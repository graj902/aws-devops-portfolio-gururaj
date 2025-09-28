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
  // This is inside the app.get('/', ...) route

try {
  const command = new GetParameterCommand({ Name: PARAMETER_NAME, WithDecryption: true });
  const ssmResponse = await ssmClient.send(command);
  const professionalSummary = ssmResponse.Parameter.Value;

  const htmlTemplate = fs.readFileSync(path.join(__dirname, '..', 'public', 'index.html'), 'utf8');
  const finalHtml = htmlTemplate.replace('{{PROFESSIONAL_SUMMARY}}', professionalSummary);

  // MODIFIED: Log success as a structured JSON object
  console.log(JSON.stringify({
      level: "info",
      message: "Successfully rendered portfolio page",
      path: "/",
      statusCode: 200
  }));

  res.send(finalHtml);
} catch (err) {
  // MODIFIED: Log errors as a structured JSON object
  console.error(JSON.stringify({
      level: "error",
      message: "Could not load configuration from backend services.",
      errorName: err.name,
      errorMessage: err.message,
      stack: err.stack // Including the stack trace for better debugging
  }));
  res.status(500).send("<h1>Error</h1><p>Could not load configuration from backend services.</p>");
}
});

app.listen(PORT, () => {
  // MODIFIED: Log the server start message as a structured JSON object
  console.log(JSON.stringify({
      level: "info",
      message: `Server running on port ${PORT}`
  }));
});