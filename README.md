# Yield Planet Channel Manager Web Services SOAP Client Java

## Information
Yield Planet's WSDL compiled by JaxWS into a Java JAR containing all generated XML objects. 

Note: The code was compiled with Jakarta EE dependencies.
Note: There is no custom written code in this module; only what came from the WSDL.

## Usage
You can use this code in one of two ways:

1. Download the JAR from Maven repo as shown below:

```
<dependency>
    <groupId>travel.wink</groupId>
    <artifactId>yield-planet-channel-manager-ws-soap-client-java</artifactId>
    <version>{{SEE RELEASES}}</version>
</dependency>
```

2. Fork this repo and customize JaxWS WSDL code generation to your liking. One thing we don't make available in our own configuration is stubbing out the service but which you can choose to do by changing the JaxWS configuration slightly. Also, if you need to use the older javax JaxWS generator, you need to update all the dependencies here and use the old codehaus JaxWs plugin. 

Type:

`mvn clean compile`

to generate the same Java code we deploy to Maven repo.
