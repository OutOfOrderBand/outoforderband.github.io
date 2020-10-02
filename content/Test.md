---
layout: post
title: "Tracking devices in UniFi WiFi"
date: 2015-12-15 00:00:01
description: "An insightful description for this page that Google will like"
---

Several years ago, we migrated from a [Cisco](http://www.cisco.com/cisco/web/UK/index.html#x6CjTZEDlwuM6WO1.97) Wi-Fi infrastructure to a [UniFi](http://www.ubnt.com/enterprise/) setup.

UniFi _(from Ubiquiti Networks)_ offer a pretty remarkable WiFi solution, especially when it comes down to cost. I shan’t go into the in’s and out’s of UniFi, as apart from anything else, I can’t claim to be an expert in the technology. In many ways, it just works!

> _What’s interesting, is the database supporting the UniFi controller is _[_MongoDB_](http://www.mongodb.org/)_ (a [NoSQL](http://en.wikipedia.org/wiki/NoSQL) database, that can be queried using JavaScript)._

Again, whilst I wouldn’t claim to be a MongoDB expert, I do like the idea of being able to use JavaScript to query data.

---

## Lost iPad

Recently, we had a situation where an iPad had gone missing. Although it is possible to establish an approximate location of a given device, using UniFi’s controller system, clearly this is only effective whilst the device is connected; the next best option is a singular ‘**last seen**’ log entry.

So in this particular instance, there wasn’t any _real_ ‘tracking’ data available to work with. However, UniFi _was_ logging connection information, so I concluded that there must be a way of _extracting_ this information from the backend.

The first thing I did was download and install a [GUI](http://en.wikipedia.org/wiki/Graphical_user_interface) based MongoDB management tool called [RoboMongo](http://robomongo.org/)_(ok I could have consoled my way to success, but the GUI just felt a little easier)._

Installing and configuring RoboMogo is really very easy. In our instance, it was just install and connect to ‘localhost’ using port 27117.

![RoboImg](https://normansolutions.co.uk/posts/files/5ad78a35-ec47-45d0-b103-2b895beaa52b.jpg =244x168 "RoboImg")

![RoboImg](https://normansolutions.co.uk/posts/files/5ad78a35-ec47-45d0-b103-2b895beaa52b.jpg)

{{< rawhtml >}}
          <img
            src="data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
            data-src="https://normansolutions.co.uk/posts/files/5ad78a35-ec47-45d0-b103-2b895beaa52b.jpg"
{{< /rawhtml >}}

## Tracking Script

> _Once RoboMongo was installed, it was then a matter of scripting out an appropriate query._

Using the _‘[beg, borrow and manipulate](https://normansolutions.co.uk/post/plotting-earthquakes-on-a-firefly-vle-page)’_ principle – I ended up with an effective script.

The script takes two parameters – a **device ID\***(which is a wildcard by default)\* and the total number of **hours **that you wish to search back.

It produces a list of results, detailing the device _(or devices_), along with every AP the device(s) has connected to, complete with the time at this location; all going back for as long you declared in hours _(or have enough data to search)._

<script src="https://gist.github.com/normansolutions/31d23709dfe158c8d000.js"></script>

<noscript><a href="https://gist.github.com/31d23709dfe158c8d000">Click for code snippet</a></noscript>

---

## Result

In our particular instance, the results were astonishing; we could trace a complete history of the device’s journey _(even though it was no longer turned on)._

I am also very happy to report that the device in question, was found safe and well.
