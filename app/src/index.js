const express = require('express');
const path = require('path');
const fs = require('fs');
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

const PORT = process.env.PORT || 8080;
const REGION = process.env.AWS_REGION || "ap-south-1";
const PARAMETER_NAME = process.env.PARAMETER_NAME || "/portfolio/prod/summary";

const app = express();
const ssmClient = new SSMClient({ region: REGION });

app.get('/style.css', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'style.css'));
});

app.get('/', async (req, res) => {
  try {
    const command = new GetParameterCommand({ Name: PARAMETER_NAME, WithDecryption: true });
    const ssmResponse = await ssmClient.send(command);
    const professionalSummary = ssmResponse.Parameter.Value;

    const htmlTemplate = fs.readFileSync(path.join(__dirname, '..', 'public', 'index.html'), 'utf8');
    const finalHtml = htmlTemplate.replace('{{PROFESSIONAL_SUMMARY}}', professionalSummary);

    res.send(finalHtml);
  } catch (err) {
    console.error("Error processing request:", err);
    res.status(500).send("<h1>Error</h1><p>Could not load configuration from backend services.</p>");
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});