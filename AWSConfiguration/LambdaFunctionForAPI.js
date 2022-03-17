const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json"
  };
 
try{
    switch (event.routeKey) {
        case "GET /items/{sku}":
           let params = {
                // Specify which items in the results are returned.
                FilterExpression: "sku = :sku",
                // Define the expression attribute value, which are substitutes for the values you want to compare.
                ExpressionAttributeValues: {
                  ":sku": parseInt(event.pathParameters.sku),
              },
                // Set the projection expression, which are the attributes that you want.
                //ProjectionExpression: "*",
                TableName: "PhamrachainSKULatestDB",
              };
          body = await dynamo.scan(params).promise();
          console.log(event.pathParameters.sku)
          console.log(params.ExpressionAttributeValues)
        break;
        default:
            throw new Error(`Unsupported route: "${event.routeKey}"`);
    }
}
catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers
  };
};