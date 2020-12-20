# Azure WordPress and Cloudflare

## Pre-requisites

* Azure account
* Cloudflare account
* Domain name
* WinSCP

## Setting up your Wordpress site on Azure

To host a Wordpress website you need to have a service that hosts the actual PHP web application and also a database to work from. Both can easily be hosted in Azure.

The first thing we will do is provision the two services we need.

* Log in the the [Azure Portal](https://portal.azure.com)
* Create a new resource group for your WordPress site in the region of your choice
* Create a new [Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/quickstart-create-mysql-server-database-using-azure-portal)
    * Search for and select `Azure Database for MySQL`
    * Most likely choose a single server depending on your expected workload
    * Choose Version `5.7` and an appropriate database size
    > Even the smallest database size is likely to be able to handle significant traffic to your site.
* Create a new App Service Plan
    * Ensure it is set to Linux and choose an appropriate pricing tier (this can be changed later so go small to start with)
* Create a new App Service
    * Linux OS
    * Runtime stack is PHP 7.4
    * Publish Code


We will be following the standard [install guide](https://wordpress.org/support/article/how-to-install-wordpress/).

## Setting up Cloudflare

* 