---
layout: post
title: "Tracking devices in UniFi WiFi"
date: 2015-12-15 00:00:01
description: "An insightful description for this page that Google will like"
---

Several years ago, we migrated from a [Cisco](<http://www.cisco.com/cisco/web/UK/index.html#x6CjTZEDlwuM6WO1.97>) Wi-Fi infrastructure to a [UniFi](<http://www.ubnt.com/enterprise/>) setup.

 UniFi *(from Ubiquiti Networks)* offer a pretty remarkable WiFi solution, especially when it comes down to cost. I shan’t go into the in’s and out’s of UniFi, as apart from anything else, I can’t claim to be an expert in the technology. In many ways, it just works!

> *What’s interesting, is the database supporting the UniFi controller is *[*MongoDB*](<http://www.mongodb.org/>)* (a [NoSQL](<http://en.wikipedia.org/wiki/NoSQL>) database, that can be queried using JavaScript).*

Again, whilst I wouldn’t claim to be a MongoDB expert, I do like the idea of being able to use JavaScript to query data.

---

## Lost iPad

Recently, we had a situation where an iPad had gone missing. Although it is possible to establish an approximate location of a given device, using UniFi’s controller system, clearly this is only effective whilst the device is connected; the next best option is a singular ‘**last seen**’ log entry.

So in this particular instance, there wasn’t any *real* ‘tracking’ data available to work with. However, UniFi *was* logging connection information, so I concluded that there must be a way of *extracting* this information from the backend.

The first thing I did was download and install a [GUI](<http://en.wikipedia.org/wiki/Graphical\_user\_interface>) based MongoDB management tool called [RoboMongo](<http://robomongo.org/>)*(ok I could have consoled my way to success, but the GUI just felt a little easier).*

Installing and configuring RoboMogo is really very easy. In our instance, it was just install and connect to ‘localhost’ using port 27117.

![RoboImg](https://normansolutions.co.uk/posts/files/5ad78a35-ec47-45d0-b103-2b895beaa52b.jpg =244x168 "RoboImg")

![RoboImg](https://normansolutions.co.uk/posts/files/5ad78a35-ec47-45d0-b103-2b895beaa52b.jpg)


## Tracking Script

> *Once RoboMongo was installed, it was then a matter of scripting out an appropriate query.*

Using the *‘[beg, borrow and manipulate](<https://normansolutions.co.uk/post/plotting-earthquakes-on-a-firefly-vle-page>)’* principle – I ended up with an effective script.

The script takes two parameters – a **device ID***(which is a wildcard by default)* and the total number of **hours **that you wish to search back.

It produces a list of results, detailing the device *(or devices*), along with every AP the device(s) has connected to, complete with the time at this location; all going back for as long you declared in hours *(or have enough data to search).*

<script gitsrc="https://gist.github.com/normansolutions/31d23709dfe158c8d000.js"></script>

<noscript><a href="https://gist.github.com/31d23709dfe158c8d000">Click for code snippet</a></noscript>

---

## Result

In our particular instance, the results were astonishing; we could trace a complete history of the device’s journey *(even though it was no longer turned on).*

I am also very happy to report that the device in question, was found safe and well.

