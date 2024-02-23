const http = require('http');

const consulServerPrivateAddr = process.env.CONSUL_SERVER_PRIVATE_ADDR;

exports.handler = async (event) => {
  // Ensure event.body is parsed to an array, or default to an empty array
  let eventServiceNames = [];
  try {
    const eventServices = event.body ? JSON.parse(event.body) : [];
    eventServiceNames = eventServices
      .filter(service => service.Instances && service.Instances.length > 0)
      .map(service => service.Name);
  } catch (error) {
    console.error("Error parsing event.body:", error);
    // Handle error or set eventServiceNames to a default value if necessary
  }

  // Fetch all services asynchronously
  const catalogOptions = {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const allServiceReq = await new Promise((resolve, reject) => {
    const req = http.request(`${consulServerPrivateAddr}/v1/catalog/services`, catalogOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve(JSON.parse(data));
      });
    });
    req.on('error', (error) => {
      reject(error);
    });
    req.end();
  });

  // Filter to find keys in allServiceReq not present in eventServiceNames
  const missingInEventBody = Object.keys(allServiceReq).filter(
    serviceName => !eventServiceNames.includes(serviceName)
  );

  // Update Consul KV with missingInEventBody
  const kvUpdateOptions = {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  await new Promise((resolve, reject) => {
    const req = http.request(`${consulServerPrivateAddr}/v1/kv/missing`, kvUpdateOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve(JSON.parse(data));
      });
    });
    req.on('error', (error) => {
      reject(error);
    });
    req.write(JSON.stringify(missingInEventBody)); // Write the serialized JSON to the request
    req.end();
  });

  // Prepare the response
  const response = {
    statusCode: 200,
    body: JSON.stringify({
      missingInEventBody,
    }),
  };

  return response;
};
