# Want to Have Features 

I want to have a powershell module that I can offload logging to. I use SEQ for logging in other project and in my DAPR environment. Now my powershell script become to important to have have a clue wants going on. 
Note: The logging function is addressed on Phase0. But I want logging statements to my central log.

The Logging feature should have a configuration that is isolated from the main script. It should be possible to setup other Logging providers. The make logging more available for powershell scripts, I think it a good idea to offload logging to a C# LoggingService or just add the logging providers in a DLL and let powershell consume the DLL?

# Spesical Feature for that use the frawmework 
- Network Probe and TCP Checker system
- 