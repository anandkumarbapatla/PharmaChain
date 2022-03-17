const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = function (event, context,callback) {
    console.log(event);
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
    
    TableName : 'TemperatureAbnomralNotification'
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
