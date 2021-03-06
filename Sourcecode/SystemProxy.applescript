(*Jason Campipsi
   name: SystemProxy
   version: v0.5
   date: 5.14.17
   Realsed under the GPL 3
   Purpose: to make switching the system-wide socks-proxy setting On or Off quick and easy

  Reference: #http://peter.upfold.org.uk/blog/2008/10/10/applescript-to-enable-socks-proxy-on-mac-os-x/
    -setsocksfirewallproxy � tells networksetup to turn the proxy on, with the following settings
  Ethernet � the identifier of the network service to change the settings for (e.g. AirPort, Ethernet). 
	Use networksetup -listallnetworkservices to see all valid values.
	127.0.0.1 � the address of the SOCKS proxy. In our case, SSH creates the proxy on the local system, so 127.0.0.1.
	8080 � the port of the SOCKS proxy. This is the -D argument in your SSH command.
	off � this is for authentication. The SSH SOCKS system doesn�t need authentication and only runs on loopback, 
		so we leave it off. If you�re using a different SOCKS system, you may need this 
		(and also give the username and password as arguments after it).
*)

property program : "SystemProxy"
property portN : "8080"
property Lhost : "127.0.0.1"
property countdown : "38"
property Title : program & ": Setup SOCKS in seconds!"

on checkIP(address)
	if address is "localhost" then
		return "true"
	end if
	
	set badAns to address & " is not a propper IP Address."
	set ASTD to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "."
	set blocks to text items of address
	if (count blocks) is not 4 then
		display dialog badAns with title program & ": poorly formed address"
		return "false"
	end if
	set AppleScript's text item delimiters to ASTD --reset
	repeat with k from 1 to 4
		try --test the ip-block if it is a number or not
			(item k of blocks) as number
		on error errStr
			set msg to badAns & return & return & (item k of blocks) & " is not a number." & return & return & "Use numbers between 0 and 255"
			exit repeat
		end try
		
		tell item k of blocks as number to if it � 0 and it < 256 then --is the ip block range 0->255?
			set msg to "true"
		else
			set msg to badAns & return & return & "Block #" & k & ": " & it & " is out of range" & return & return & "Use numbers between 0 and 255"
			exit repeat
		end if
	end repeat
	
	if msg is "true" then
		return "true"
	else
		try
			display dialog msg with title program & ": Unusable Address Given" giving up after countdown
		on error StrError
			return null
		end try
	end if
	return "false"
end checkIP

on getIP()
	try --get proxy address
		set bttnPress to display dialog "Proxy Address:" default answer Lhost with title Title giving up after countdown
		set address to text returned of result as string
	on error
		--display dialog "getIP null^0 Error try failed"
		return null
	end try
	if bttnPress is "Cancel" then
		--display dialog "getIP null^1 ButtonPress Cancel"
		return null
	end if
	return address
end getIP

on run
	set buttonChoices to {"Cancel", "On", "Off"}
	set cmd to "networksetup -setsocksfirewallproxystate Ethernet off" --assume the proxy should be off
	try
		set r to button returned of (display dialog "Turn System Sock Proxy On or Off?" buttons buttonChoices default button "Cancel" with title Title giving up after countdown)
	on error StrError
		return
	end try
	
	if r is "Cancel" then --exit?
		--display dialog "Cancel run exit "
		return
	else if r is "On" then -- turn the proxy on?
		repeat --get the HOSTname
			set HOSTName to getIP()
			--display dialog "hostname is this: " & HOSTName with title Title
			if HOSTName is null then
				--display dialog "Null HOSTName"
				return -- cancel was selected, quit
			end if
			
			set r to checkIP(HOSTName) --is ip address in a valid form?
			--display dialog "checkIP result is this: " & r
			if r is null then
				--display dialog "checkIP returned Null exit "
				return -- cancel was selected, quit
			else if r is "true" then
				--display dialog "checkIP result is true"
				exit repeat
			end if
		end repeat
		
		repeat --get port to bind the service too
			try
				set r to display dialog "Please enter a port number:" default answer portN with title Title giving up after countdown
				set portNumber to round (text returned of result as number) --the port must be a whole number
				if portNumber > 0 then --valid port # must be 1 or higher
					exit repeat
				end if
			on error StrError
				try
					display dialog "This is not a number: " & text returned of result with title program & " Error: positive number must be given"
				on error StrError
					error number -128 --User Cancelled"
				end try
			end try
		end repeat
		if r is "Cancel" then --exit?
			display dialog "Time to leave"
			return
		end if
		set cmd to "networksetup -setsocksfirewallproxy Ethernet" & space & HOSTName & space & portNumber & space & "off"
	end if
	
	try --change the system socks proxy settings
		do shell script cmd with administrator privileges
	on error StrError
		say "SystemProxy Error: changing the setting known as 'networksetup -setsocksfirewallproxy Ethernet'!"
	end try
end run
