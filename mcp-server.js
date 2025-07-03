#!/usr/bin/env node

/**
 * Custom MCP server for Braintree iOS SPM
 * This server can be used to listen for webhook events from GitHub
 * and trigger updates to the SPM package.
 */

const http = require('http');
const https = require('https');
const { exec } = require('child_process');
const crypto = require('crypto');
require('dotenv').config();

// Configuration
const PORT = process.env.PORT || 3000;
const GITHUB_SECRET = process.env.GITHUB_SECRET;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const BRAINTREE_REPO = process.env.BRAINTREE_REPO || 'braintree/braintree_ios';
const DEBUG = process.env.DEBUG === 'true';

// Validate required environment variables
if (!GITHUB_SECRET || GITHUB_SECRET === 'your-webhook-secret') {
  console.error('Error: GITHUB_SECRET environment variable is required');
  process.exit(1);
}

if (!GITHUB_TOKEN || GITHUB_TOKEN === 'your-github-token') {
  console.error('Error: GITHUB_TOKEN environment variable is required');
  process.exit(1);
}

// Create HTTP server
const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/webhook') {
    handleWebhook(req, res);
  } else if (req.method === 'GET' && req.url === '/health') {
    res.statusCode = 200;
    res.end('OK');
  } else {
    res.statusCode = 404;
    res.end('Not Found');
  }
});

// Handle GitHub webhook
function handleWebhook(req, res) {
  let body = '';
  
  req.on('data', chunk => {
    body += chunk.toString();
  });
  
  req.on('end', () => {
    try {
      // Verify webhook signature
      const signature = req.headers['x-hub-signature-256'];
      if (!signature) {
        console.error('No signature provided');
        res.statusCode = 401;
        res.end('Unauthorized');
        return;
      }
      
      const hmac = crypto.createHmac('sha256', GITHUB_SECRET);
      const digest = 'sha256=' + hmac.update(body).digest('hex');
      if (signature !== digest) {
        console.error('Invalid signature');
        res.statusCode = 401;
        res.end('Unauthorized');
        return;
      }
      
      const event = JSON.parse(body);
      const eventType = req.headers['x-github-event'];
      
      // Handle release events from Braintree iOS repo
      if (eventType === 'release' && event.repository.full_name === BRAINTREE_REPO && event.action === 'published') {
        const version = event.release.tag_name;
        console.log(`New Braintree iOS release detected: ${version}`);
        
        // Update the package
        updatePackage(version, event.release.assets)
          .then(() => {
            res.statusCode = 200;
            res.end('Webhook processed successfully');
          })
          .catch(err => {
            console.error('Error updating package:', err);
            res.statusCode = 500;
            res.end('Internal Server Error');
          });
      } else {
        if (DEBUG) {
          console.log(`Ignoring event: type=${eventType}, repo=${event.repository?.full_name}, action=${event.action}`);
        }
        res.statusCode = 200;
        res.end('Event ignored');
      }
    } catch (err) {
      console.error('Error processing webhook:', err);
      res.statusCode = 400;
      res.end('Bad Request');
    }
  });
  
  req.on('error', err => {
    console.error('Error receiving webhook:', err);
    res.statusCode = 500;
    res.end('Internal Server Error');
  });
}

// Update package with new Braintree version
function updatePackage(version, assets) {
  return new Promise((resolve, reject) => {
    // Configure git with token for authentication
    exec(`git config --global url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"`, (error) => {
      if (error) {
        console.error(`Error configuring git: ${error}`);
        return reject(error);
      }
      
      // Execute the update script
      exec(`./update-framework.sh ${version}`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error executing update script: ${error}`);
          if (stderr) console.error(`stderr: ${stderr}`);
          return reject(error);
        }
        
        if (DEBUG) {
          console.log(`Update script output: ${stdout}`);
        }
        
        // Commit and push changes
        const commitMessage = `Update to Braintree iOS SDK ${version}`;
        exec(`git add . && git commit -m "${commitMessage}" && git tag -a "v${version}" -m "Version ${version}" && git push origin main --tags`, (error, stdout, stderr) => {
          if (error) {
            console.error(`Error pushing changes: ${error}`);
            if (stderr) console.error(`stderr: ${stderr}`);
            return reject(error);
          }
          
          if (DEBUG) {
            console.log(`Changes pushed: ${stdout}`);
          }
          resolve();
        });
      });
    });
  });
}

// Start server
server.listen(PORT, () => {
  console.log(`MCP Server running on port ${PORT}`);
  console.log(`Listening for webhook events from ${BRAINTREE_REPO}`);
  if (DEBUG) {
    console.log('Debug mode enabled');
  }
}); 