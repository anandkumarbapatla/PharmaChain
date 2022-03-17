const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

let test;

exports.handler = function (event, context,callback) {
    const truncateTable = async () => {
  let result

  do {
    result = await dynamo.scan({
      TableName: "PhamrachainSKULatestDB",
      test
    }).promise()
    
    test = result.LastEvaluatedKey;

    console.log(`Found ${result.Items.length} Items, removing...`)

    if (result.Items.length > 0) {
      await Promise.all(
        result.Items.map(async item =>
          dynamo.delete({
            TableName: "PhamrachainSKULatestDB",
            Key: {
              timestamp: item.timestamp,
            },
          }).promise()
        )
      )
    }
  } while (result.Items.length || result.LastEvaluatedKey)
}

truncateTable()
  .then(() => addToTable())
  .catch(console.error);
  
   const addToTable = async () =>{
  var params={
        Item:{
        timestamp: event['timestamp'],
        latitude: event['latitude'],
        longitude: event['longitude'],
        sku : event['sku'],
        lot : event['lot'],
        drugname : event['drugname'],
        temperature : event['temperature'],
        humidity : event['humidity']
    },
    
    TableName : 'PhamrachainSKULatestDB'
    };
    dynamo.put(params, function(err,data){
        if(err){
            callback(err,null);
        }
        else{
            callback(null,null);
        }
    });
}
}