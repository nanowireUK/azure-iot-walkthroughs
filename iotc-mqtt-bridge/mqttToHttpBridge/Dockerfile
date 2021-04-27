# Use SDK to build release package
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build-img
WORKDIR /app
COPY . ./
RUN dotnet --info
RUN dotnet publish -c Release -o out

# Use runtime for final image
FROM mcr.microsoft.com/dotnet/runtime:5.0
WORKDIR /app
COPY --from=build-img /app/out ./
ENTRYPOINT ["dotnet", "mqttToHttpBridge.dll"]