using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Client.Options;
using MQTTnet.Protocol;

namespace mqttToHttpBridge
{
    class Program
    {
        //Note : change IP if needed
        protected static string mqttBrokerAddress = "";
        protected static string mqttClientId = "";
        protected static string mqttUser = "";
        protected static string mqttPassword = "";
        protected static string mqttTopic = "";
        protected static string httpUrl = "";
        protected static string httpApiKey = "";

        private static readonly HttpClient httpClient = new HttpClient();

        static async Task Main(string[] args)
        {
            // Set up mqttClient
            var mqttClient = new MqttFactory().CreateMqttClient();
            var options = new MqttClientOptionsBuilder()
                .WithClientId(mqttClientId)
                .WithWebSocketServer(mqttBrokerAddress)
                //.WithTcpServer(mqttBrokerAddress)
                .WithCredentials(mqttUser, mqttPassword)
                .WithTls()
                //.WithCleanSession()
                .Build();            

            mqttClient.UseApplicationMessageReceivedHandler(async e =>
            {
                var parsedMessage = parseMqttMessage(e.ApplicationMessage.Payload);
                await sendDeviceMessage(parsedMessage);
                /*Console.WriteLine($"+ Topic = {e.ApplicationMessage.Topic}");
                Console.WriteLine($"+ Payload = {Encoding.UTF8.GetString(e.ApplicationMessage.Payload)}");
                Console.WriteLine($"+ QoS = {e.ApplicationMessage.QualityOfServiceLevel}");
                Console.WriteLine($"+ Retain = {e.ApplicationMessage.Retain}"); */
            });

            mqttClient.UseConnectedHandler(async e =>
            {
                Console.WriteLine("Connected to MQTT Server");

                // Subscribe to a topic
                await mqttClient.SubscribeAsync(new MqttTopicFilterBuilder().WithTopic(mqttTopic).Build());
            });

            await mqttClient.ConnectAsync(options, CancellationToken.None);

            Console.WriteLine("Press any key to close MQTT - HTTP bridge");
            Console.ReadKey();
            await mqttClient.DisconnectAsync();
        }

        private static IoTCMessage parseMqttMessage(byte[] payload) {
            var stringPayload = Encoding.UTF8.GetString(payload);
            IoTCMessage iotcMessage = new IoTCMessage(); 

            var jsonElement = JsonDocument.Parse(stringPayload).RootElement;

            iotcMessage.payload.creationTimeUtc = jsonElement.GetProperty("time").ToString();

            var device = jsonElement.GetProperty("device");
            iotcMessage.deviceId = device.GetProperty("id").ToString();
            iotcMessage.modelId = device.GetProperty("driver").ToString();

            var state = jsonElement.GetProperty("state");
            if(state.GetProperty("payload").ValueKind == JsonValueKind.Object)
                iotcMessage.payload.data = state.GetProperty("payload");
            else {
                iotcMessage.payload.data = new { raw = state.GetProperty("payload").ToString()};
            }

            return iotcMessage;
        }

        private static async Task sendDeviceMessage(IoTCMessage iotcMessage){
            httpClient.DefaultRequestHeaders.Accept.Clear();
            httpClient.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));

            var content = iotcMessage.GetPayloadAsStringContent();
            content.Headers.Add("x-api-key",httpApiKey);

            var completeUrl = String.Format("{0}/devices/{1}/messages/events",httpUrl,iotcMessage.deviceId);
            Console.WriteLine(completeUrl);
            await httpClient.PostAsync(completeUrl, content);
        }
    }
    
    class IoTCMessage {
        public string deviceId;
        public string modelId;
        public IoTCPayload payload { get; set; }

        public IoTCMessage() {
            payload = new IoTCPayload();
        }

        public StringContent GetPayloadAsStringContent() {
            var serializedJson = JsonSerializer.Serialize(payload);
            Console.WriteLine(serializedJson);
            return new StringContent(serializedJson, Encoding.UTF8, "application/json");
        }
    }

    class IoTCPayload {
        public dynamic data { get; set; }
        public string properties { get; set; }
        public string creationTimeUtc { get; set; }
        public string componentName { get; set; }
    }
}
