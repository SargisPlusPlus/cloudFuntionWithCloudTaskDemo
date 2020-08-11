const express = require('express');
const { CloudTasksClient } = require('@google-cloud/tasks');

const records = [
  { name: "A" },
  { name: "B" },
];

async function enqueue(record) {
  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url: 'https://google.com', // Add your URL Here
      headers: {
        'content-type': 'application/json',
      },
      body: Buffer.from(JSON.stringify(record)).toString('base64'),
    }
  };
  // Better to make this global and initialize once
  const client = new CloudTasksClient();
  const parent = client.queuePath(process.env.GCLOUD_PROJECT, process.env.LOCATION, 'my-queue')
  const request = { parent, task };
  const [response] = await client.createTask(request);
  const { name } = response;
  console.log("Name", name);
}

async function myFunction(request, response) {
  for (const record of records) {
    await enqueue(record);
  }
  return response.status(200).send({
    text: "hello world",
  });
}

function buildApp() {
  const app = express();
  app.use(require('body-parser').json());
  // Custom routes below

  app.use(myFunction);
  return app;
}

exports.myFunction = buildApp();
