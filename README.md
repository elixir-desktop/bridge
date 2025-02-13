# Bridge

The `Bridge` is part of the elixir-desktop project and bridges all `wxWidgets` calls that an Elixir application is making to 
a connected tcp-connection. This allows externalizing platform UI on Android and iOS to the native widgets instead of porting `wxWidgets` there. 

# Usage

The `Bridge` will be pulled in automatically by mobile builds of the `elixir-desktop` project. It uses a system environment variable `BRIDGE_PORT` to know on which TCP-port the bridge server is listening. 

To understand how this is working in practice, check the Android example app that implements a bridge server.

__Work in progress__ but used in production on Android and iOS for [Diode Collab](https://diode.io).