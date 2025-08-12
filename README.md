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
    - /usr/local/freeswitch/bin/freeswitch -nonat
  - sngrep2:
    - sngrep2 -d any
  - samples:
    - cd /root/src/git/learning-freeswitch/samples

```

Obs: sngrep2 is a fork of sngrep with support for RFC2833 DTMF and MRCP support.

## Test-based development

When developing solutions with freeswitch, we need to provide test scripts confirming their proper behavior.

So we use node.js [zeq](https://github.com/MayamaTakeshi/zeq) module that permits to specify functional tests.

This is a simple library that permits to sequence execution of commands and wait for events triggered by the commands.

Then [sip-lab](https://github.com/MayamaTakeshi/sip-lab) is used to make/receive SIP calls.

So we combine these two libraries to write functional SIP tests. You can see a sample here: https://github.com/MayamaTakeshi/sip-lab/blob/master/samples/simple.js

## Running a sample test script

Once inside the container, switch to the 'samples' window and do:

```
npm i
```

The above will install node.js modules required by the test script.

After it finishes, create config/default.json by doing:
```
cp config/default.json.sample config/default.js
```
and update the value of local_ip:
{
  "local_ip": "192.168.0.113"
}

with the value of the ipv4 address used by freeswitch:
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

As we can see, the above will execute this lua script:
```
takeshi@takeshi-desktop:learning-freeswitch$ cat scripts/hello.lua 
session:answer()

session:sleep(500)

session:execute("echo")
```

which answers the call, sleeps for 500 milliseconds (need to make sure the voice path is open) and execute application 'echo' which echoes all audio back to the caller. 

The echo.js script then sends some DTMF and wait for their echo and terminates the call.

Once the script finishes, switch to the 'sngrep2' window and check how the SIP communication between sip-lab and freeswitch was done.

Then switch to the 'freeswitch' window and inspect the freeswitch output.


## Configuring freeswitch

Configuration of freeswitch involves several files depending of the modules/features you are using.

The configuration starts from /usr/local/freeswitch/conf/freeswitch.xml (this file includes/loads all the other configuration files).

But for the scope of this learning material we will concentrate on the diaplan and lua module.

Documentation:

 https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Dialplan/

 https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_lua_1048944/

Obs: for dialplan, it is good to check the xml files under /usr/local/freeswitch/conf/dialplan/ as they contain several samples showing how it can be used.

So when testing with dialplan or lua scripts, you can change the files in the folders 'conf/dialplan/public' and 'scripts' in this repo as they are mapped to the proper folders insinde the container at

/usr/local/freeswitch/conf/dialplan/public

and

/usr/local/freeswitch/scripts

(see start_container.sh).

## Using baresip to listen to freeswitch output.

Using sip-lab inside the container, we cannot listen to audio output from freeswitch. 

This is not strictly necessary as since we automate tests when working, nobody will actually listen anything.

But sometimes we might actually need to interact with freeswitch during troubleshooting/debugging so we will need a sip phone.

A good option is [baresip](https://github.com/baresip/baresip) which is a command-line sip phone that you can run in your desktop PC.

Follow its github page on how to build it or install it using your OS package manager if available.

Then set this account line in ~/.baresip/accounts to permit to talk with freeswitch:
```
<sip:1000@test1.com>;outbound="sip:192.168.0.113:5060";auth_pass=1234
```

Obs: change '192.168.0.113' with your local ip address (the ip address listened by freeswitch).

Then you can make a call to freeswitch this way:
```
baresip -e 'dsip:9198@test1.com'
```

The above destination, sip:9198, will play a song using tones.

And you can try other destinations like:

9195: delay_echo (echo audio back after a delay)

9196: echo (echo audio back)

See: /usr/local/freeswitch/conf/dialplan/default.xml

