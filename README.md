# learning-freeswitch

## Overview

This repo provides tools to quickly get up to speed working with freeswitch using [zeq](https://github.com/MayamaTakeshi/zeq) and [sip-lab](https://github.com/MayamaTakeshi/sip-lab) to write functional tests.

Here we have a Dockerfile that permits to build a docker image with freeswitch, node.js (used to run functional tests) and sngrep2 (used to follow SIP message flows)

The freeswitch in the image is set up with two SIP interfaces: 
  - default (UDP port 5060): used by SIP terminals (requiring authentication)
  - public (UDP port 5080): used by gateways (no authentication)

## Building the image:
```
./build_image.sh
```

## Starting the container:
```
./start_container.sh
```

Once you are inside the container, you can start a tmux session for work by doing:
```
./tmux_session.sh
```

This will create the tmux session specified in tmux_session.yml:
```
name: learning-freeswitch
root: ~/

windows:
  - freeswitch:
    - sudo /usr/local/freeswitch/bin/freeswitch -nonat
  - sngrep2:
    - sudo sngrep2 -d any
  - samples:
    - cd ~/src/git/learning-freeswitch/samples

```

The 'freeswitch' window will have freeswitch in CLI mode. So you can experiment issuing commands to it (try 'help').

Obs: sngrep2 is a fork of [sngrep](https://github.com/irontec/sngrep) with support for parsing of RFC2833 DTMF and MRCP.

## Test-driven development

When developing solutions, we need to provide test scripts confirming their proper behavior.

So we use node.js [zeq](https://github.com/MayamaTakeshi/zeq) module that permits to write functional tests.

This is a simple library that permits to sequence execution of commands and wait for events triggered by the commands.

Then [sip-lab](https://github.com/MayamaTakeshi/sip-lab) is used to make/receive SIP calls and perform media operations (play/record audio files, detect digits, send receive fax, etc).

So we combine these two libraries to write functional SIP tests.

You can see a generic sample (not involving freeswitch) here: https://github.com/MayamaTakeshi/sip-lab/blob/master/samples/simple.js

## Running a sample test script

Inside the container, in the tmux session, switch to the 'samples' window and do:

```
npm i
```

The above will install node.js modules required by the test script.

After it finishes, create config/default.json by doing:
```
cp config/default.json.sample config/default.json
```
and update the value of local_ip:
```
{
  "local_ip": "192.168.0.113"
}
```
with the value of the ipv4 address used by freeswitch that can obtained like this:
```
root@takeshi-desktop:~# netstat -upnl|grep 5060             
udp        0      0 192.168.0.113:5060      0.0.0.0:*                           663/freeswitch      
udp6       0      0 ::1:5060                :::*                                663/freeswitch 
```


Then  you can run the sample script by doing:
```
node echo.js
```
The above makes a call to 05011112222 at freeswitch public interface that reaches this configuration file:
```
takeshi@takeshi-desktop:learning-freeswitch$ cat conf/dialplan/public/mylua.xml 
<include>
  <extension name="public_mylua">
    <condition field="destination_number" expression="^05011112222">
      <action application="lua" data="hello.lua"/>
    </condition>
  </extension>
</include>
```

The above will execute this lua script:
```
takeshi@takeshi-desktop:learning-freeswitch$ cat scripts/hello.lua 
session:answer()

session:sleep(500)

session:execute("echo")
```

which answers the call, sleeps for 500 milliseconds (need to make sure the voice path is open) and execute application 'echo' which echoes all audio it receives back to the caller. 

The echo.js script then sends some DTMF digits and wait for their echo and terminates the call.

Once the script finishes, switch to the 'sngrep2' window and check how the SIP communication between sip-lab and freeswitch was done.

Then switch to the 'freeswitch' window and inspect the freeswitch output.

So study the echo.js script and try to correlate it with the output in the tmux windows.

## Event matching

The [zeq](https://github.com/MayamaTakeshi/zeq) performs event matching when 
```
await z.wait(LIST_OF_EVENTS_TO_WAIT_FOR, TIMEOUT)
```
is called.

The event matching is performed by [data-matching](https://github.com/MayamaTakeshi/data-matching).

A matching event specification can be as simple as something like this:
```
{
  event: 'something_happened',
}
```
Then if an event like:
```
{
  event: 'something_happened',
  param1: 'abc',
  param2: 'def',
}
````
is received, there will be a match because by default, we do a partial match, meaning we don't care about all the parameters in the event and we are interested in specific fields in the event (in the above, only the event name matters).

Also, we can pass functions to perform the match. See: https://github.com/MayamaTakeshi/data-matching/tree/master?tab=readme-ov-file#using-matching-functions

Then regarding matching SIP messages, when inspecting the output of 'node echo.js' you might notice this:
```
06:14:25.363  wait (echo.js:42) got event:                                                                                                                                                                                 [308/1867]
06:14:25.363    {                                                                                                 
    event: 'response',                                                                                            
    call_id: 0,                                                                                                                                                                                                                      
    method: 'INVITE',                                                                                             
    msg: 'SIP/2.0 200 OK\r\n' +                                                                                                                                                                                                      
  'Via: SIP/2.0/UDP 192.168.0.113:5061;rport=5061;branch=z9hG4bKPjc5d5d4ce-0eaf-4f9d-89a4-753dfa916bcb\r\n' +
  'From: <sip:0312341234@test.com>;tag=80d3b5c8-1e3c-421c-af25-93d936bb1c33\r\n' +                                
  'To: <sip:05011112222@192.168.0.113>;tag=DDcU1ZD07QrFc\r\n' +                                                   
  'Call-ID: 44cafe81-2daa-433f-bd07-f0221bed5159\r\n' +  
  'CSeq: 22338 INVITE\r\n' +                             
  'Contact: <sip:05011112222@192.168.0.113:5080;transport=udp>\r\n' +                                             
  'User-Agent: FreeSWITCH-mod_sofia/1.10.7-dev+git~20210825T173719Z~dd2411336f~64bit\r\n' +                       
  'Accept: application/sdp\r\n' +
  'Allow: INVITE, ACK, BYE, CANCEL, OPTIONS, MESSAGE, INFO, UPDATE, REGISTER, REFER, NOTIFY\r\n' +                
  'Supported: timer, path, replaces\r\n' +                                                                        
  'Allow-Events: talk, hold, conference, refer\r\n' +                                                             
  'Content-Type: application/sdp\r\n' +                
  'Content-Disposition: session\r\n' +                                                                            
  'Content-Length: 257\r\n' +                                                                                     
  'Remote-Party-ID: "05011112222" <sip:05011112222@192.168.0.113>;party=calling;privacy=off;screen=no\r\n' +      
  '\r\n' +                                             
  'v=0\r\n' +               
  'o=FreeSWITCH 1755095157 1755095158 IN IP4 192.168.0.113\r\n' +                          
  's=FreeSWITCH\r\n' +     
  'c=IN IP4 192.168.0.113\r\n' +          
  't=0 0\r\n' +                           
  'm=audio 24508 RTP/AVP 0 120\r\n' +
  'a=rtpmap:0 PCMU/8000\r\n' +                                                                                                                                                                                                       
  'a=rtpmap:120 telephone-event/8000\r\n' +                                                                                                                                                                                          
  'a=fmtp:120 0-16\r\n' +
  'a=ptime:20\r\n' +
  'a=rtcp:24509 IN IP4 192.168.0.113\r\n'
  }
06:14:25.363  
06:14:25.363  Trying match against expected_events[0]:
06:14:25.364    partial_match({
    event: 'response',
    call_id: 0,
    method: 'INVITE',
    msg: sip_msg({
      $rs: '200',
      $rr: 'OK'
    })
  })
06:14:25.364  Match successful
```
As we can see, there was a match. But the msg field matching is done by a function sip_msg (from [sip-matching](https://github.com/MayamaTakeshi/sip-matching)).

This is because it would be very hard to match a raw SIP message as:
  - the order of headers might differ
  - the value of the header Call-ID is generated randomically
  - the value of params like branch, tag in header values would also be generated randomically

So instead, we use sip_msg by passing a dict containing the fields we are intersted in and it will generate a matching function that will:
  - parse the raw SIP message
  - try to match each field specified in the dict

The parsing of the SIP message is performed by [sip-parsing](https://github.com/MayamaTakeshi/sip-parsing) which permits to access SIP message fields using opensips/kamailio/openser pseudo-variable syntax.

So in:
```
    msg: sip_msg({
      $rs: '200',
      $rr: 'OK'
    })
```
we are saying the reply status ($rs) must be '200' and the reply reason ($rr) must be 'OK'.

## Configuring freeswitch

Configuration of freeswitch involves several files depending of the modules/features you are using.

The configuration starts from /usr/local/freeswitch/conf/freeswitch.xml (this file have directives to include all the other configuration files).

But for the scope of this learning material we will concentrate on the diaplan and lua module.

Roughly, the dialplan specifies what should be done when a call arrives. 

Based on parameters like the destination number it decides what actions (answer, refuse, play audio file, send fax etc) should be performed.

These actions can be specified using XML but alternatively, we can delegate the control of the call to programming language like lua and javascript.

In our case, we will be using lua (provided by module mod_lua).

Documentation:

 https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Dialplan/

 https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_lua_1048944/

Obs: for dialplan, it is good to check the xml files under /usr/local/freeswitch/conf/dialplan/ as they contain several samples showing how it can be used.

So when testing with dialplan or lua scripts, you can change the files in the folders 'conf/dialplan/public' and 'scripts' in this repo as they are mapped to the proper folders inside the container at

/usr/local/freeswitch/conf/dialplan/public

and

/usr/local/freeswitch/scripts

(see start_container.sh).

## Using baresip to listen to freeswitch output

Using sip-lab inside the container, we cannot listen to audio output from freeswitch. 

This is not strictly necessary as since we use test automation, nobody is supposed to listen to anything.

But sometimes we might need to interact with freeswitch during troubleshooting/debugging and speak/listen to audio so we will need a sip phone.

A good option is [baresip](https://github.com/baresip/baresip) which is a command-line sip phone that you can run in your desktop PC.

Follow its github page on how to build it or install it using your OS package manager if available.

Then set this account line in ~/.baresip/accounts to permit to talk with freeswitch:
```
<sip:1000@test1.com>;auth_pass=1234

```
The freeswitch configuration is set with 20 SIP accounts (SIP usernames from 1000 to 1019) with the same password '1234'.


Then you can make a call to freeswitch this way:
```
baresip -e 'dsip:9198@192.168.0.113'
```
Obs: change '192.168.0.113' with your local ip address (the ip address listened by freeswitch).

The above is instructing bare sip to execute a 'd' (dial) command to destination sip:9198@192.168.0.113.

This destination 9198 is processed by a dialplan entry that will play a song using tones. You can finish the call by pressing 'Control-C'.

Then you can try other destinations like:

9195: delay_echo (echo audio back after a delay)

9196: echo (echo audio back)

See: /usr/local/freeswitch/conf/dialplan/default.xml

Obs: when checking the SIP flows at the 'sngrep2' window, you will see REGISTER and NOTIFY flows too in addition to the INVITE flow.

This is because since we are using the freeswitch default endpoint (used for SIP terminals) we will have these things as they are part of typical SIP terminal operation:
  - REGISTER is used to inform freeswitch where the terminal can be contacted in case someone needs to talk to its user
  - NOTIFY is used for miscelaneous information the terminal might want send to the server (but in this case, freeswitch doesn't care about it).

## Exercises

Create a folder named exercises and create the following scripts inside it:

  1. send_fax.js: send a fax to freeswitch (send artifacts/sample.tiff)
  2. receive_fax.js: receive a fax from freeswitch (instruct freeswitch to send artifacts/sample.tiff)
  3. user2user.js: perform SIP REGISTER simulating terminals for accounts 1000 and 1001 and make a call from 1000 to 1001. Exchange DTMF between them and terminate the call.
  4. gateway2user.js: perform SIP REGISTER simulating a terminal for account 1000 and make a call simulating gateway that will reach the terminal. Exchange DTMF between them and terminate the call.

For each javascript file, create the equivalent lua script (at folder scripts, with the same name but with suffix '.lua') to execute the specified action and add an entry to call the lua script at conf/dialplan/public/mylua.xml. 

You can reload the dialplan by doing 'reloadxml' at the 'freeswitch' window (CLI).

You can find samples on how to do these things directly between sip-lab endpoints here: https://github.com/MayamaTakeshi/sip-lab/tree/master/samples

For gateway2user.lua, you will need to research freeswitch documentation (or ask ChatGPT etc) on how to connect (bridge) to a REGISTERed terminal.

How to write the javascript files: 

We don't need to write the full file at once. 

We just start executing some command and wait for something to happen. 

So for example, we start executing a command like sip.call.create() and then right after it we add 'await z.sleep(5000)' and see how freeswitch reacts to it (the sleep would likely be interrupted by some event).

Then if the reaction is not what we expect or the sleep times out, we correct our command(s) and/or freeswitch config files/scripts till we get the expected event(s).

Then the expected event is added in a 'await z.wait()' command and then we add the next command and so on till we get the expected behavior of the system under development/test.





