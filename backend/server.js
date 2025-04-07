const express = require('express');
const cors = require('cors');
const winston = require('winston');
const axios = require('axios'); // Add axios
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Winston logger configuration
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({ format: winston.format.simple() }),
    new winston.transports.File({ filename: 'logs/server.log' })
  ]
});

// Log requests
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  next();
});

// Authentication route
app.post('/auth', async (req, res) => {
  const { clientId, clientSecret } = req.body;

  if (!clientId || !clientSecret) {
    return res.status(400).json({ message: 'Client ID and Client Secret are required' });
  }

  try {
    const authUrl = 'https://developer.api.autodesk.com/authentication/v2/token';
    const params = new URLSearchParams();
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);
    params.append('grant_type', 'client_credentials');
    params.append('scope', 'account:read account:write data:read data:write');

    logger.info(`Authenticating with Autodesk API: ${authUrl}`);

    const response = await axios.post(authUrl, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    logger.info(`Authentication successful: ${response.status}`);
    res.json(response.data);
  } catch (error) {
    logger.error(`Authentication failed: ${error.message}`);
    res.status(500).json({ message: 'Authentication failed', error: error.message });
  }
});

// Route to fetch available hubs
app.get('/hubs', async (req, res) => {
  const accessToken = req.headers.authorization?.split(' ')[1];

  if (!accessToken) {
    return res.status(401).json({ message: 'Access token is required' });
  }

  try {
    const hubsUrl = 'https://developer.api.autodesk.com/project/v1/hubs';
    logger.info(`Fetching hubs from Autodesk API: ${hubsUrl}`);

    logger.info(`Request headers: ${JSON.stringify(req.headers)}`);
    const response = await axios.get(hubsUrl, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });

    logger.info(`Successfully fetched hubs: ${response.status}`);
    logger.info(`Response data: ${JSON.stringify(response.data.data)}`);
    res.json(response.data.data); // Send only the hub data
  } catch (error) {
    logger.error(`Failed to fetch hubs: ${error.message}`);
    res.status(500).json({ message: 'Failed to fetch hubs', error: error.message });
  }
});

app.get('/projects', async (req, res) => {
  res.status(404).json({ message: 'This endpoint is deprecated. Please use /hubs/:hub_id/projects' });
});

// Route to fetch projects for a specific hub
app.get('/hubs/:hub_id/projects', async (req, res) => {
  const { hub_id } = req.params;
  const accessToken = req.headers.authorization?.split(' ')[1];

  if (!accessToken) {
    return res.status(401).json({ message: 'Access token is required' });
  }

  if (!hub_id) {
    return res.status(400).json({ message: 'Hub ID is required' });
  }

  try {
    const projectsUrl = `https://developer.api.autodesk.com/project/v1/hubs/${hub_id}/projects`;
    logger.info(`Fetching projects from Autodesk API: ${projectsUrl}`);

    logger.info(`Request headers: ${JSON.stringify(req.headers)}`);
    const response = await axios.get(projectsUrl, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });

    logger.info(`Successfully fetched projects: ${response.status}`);
     logger.info(`Response data: ${JSON.stringify(response.data.data)}`);
    res.json(response.data.data); // Send only the project data
  } catch (error) {
    logger.error(`Failed to fetch projects: ${error.message}`);
    res.status(500).json({ message: 'Failed to fetch projects', error: error.message });
  }
});

// Route to fetch top-level folders for a specific project
app.get('/hubs/:hub_id/projects/:project_id/topFolders', async (req, res) => {
  const { hub_id, project_id } = req.params;
  const accessToken = req.headers.authorization?.split(' ')[1];

  if (!accessToken) {
    return res.status(401).json({ message: 'Access token is required' });
  }

  if (!hub_id) {
    return res.status(400).json({ message: 'Hub ID is required' });
  }

  if (!project_id) {
    return res.status(400).json({ message: 'Project ID is required' });
  }

  try {
    const topFoldersUrl = `https://developer.api.autodesk.com/project/v1/hubs/${hub_id}/projects/${project_id}/topFolders`;
    logger.info(`Fetching top-level folders from Autodesk API: ${topFoldersUrl}`);

    const response = await axios.get(topFoldersUrl, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });

    logger.info(`Successfully fetched top-level folders: ${response.status}`);
    
    // Return the top-level folders directly, without fetching their contents
    // This allows the frontend to filter and display only the "Project Files" folder
    if (response.data && Array.isArray(response.data.data)) {
      res.json(response.data.data);
    } else {
      logger.warn('Unexpected response format from Autodesk API');
      res.status(500).json({ message: 'Unexpected response format from Autodesk API' });
    }
  } catch (error) {
    logger.error(`Failed to fetch top-level folders: ${error.message}`);
    res.status(500).json({ message: 'Failed to fetch top-level folders', error: error.message });
  }
});

// Proxy endpoint for download API to avoid CORS issues
app.post('/proxy/download', async (req, res) => {
 try {
   const { api_key, ...downloadParams } = req.body;
   
   if (!api_key) {
     return res.status(400).json({ message: 'API key is required' });
   }
   
   logger.info(`Proxying download request to download API`);
   
   // Forward the request to the download API
   const downloadUrl = 'http://localhost:5001/api/v1/download';
   const response = await axios.post(downloadUrl, downloadParams, {
     headers: {
       'Content-Type': 'application/json',
       'X-API-Key': api_key
     }
   });
   
   logger.info(`Download API responded with status ${response.status}`);
   
   // Return the download API response
   res.status(response.status).json(response.data);
 } catch (error) {
   logger.error(`Download proxy error: ${error.message}`);
   
   // Forward any error response from the download API
   if (error.response) {
     return res.status(error.response.status).json(error.response.data);
   }
   
   // Generic error if no response from download API
   res.status(500).json({
     message: 'Failed to proxy download request',
     error: error.message
   });
 }
});

app.listen(port, () => {
 logger.info(`Server is running on port ${port}`);
});