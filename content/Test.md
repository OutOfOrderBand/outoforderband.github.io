---
layout: post
title: "Test Titles"
date: 2015-12-15 00:00:01
description: "An insightful description for this page that Google will like"
---

Secure access to a webpage, without the need for a logon, can often be viewed as a bit of a holy grail solution.

 Recently, I introduced a frictionless *(logon free) *way of providing *secure(ish)* access to some very basic web services.

*….I can hear all those security experts screaming already!*

> *Before I proceed any further, please note that this solution **must never be seen as a proper security authentication replacement!***

What this can be viewed as, is an ideal solution for those ‘*edge’* cases, where you may have a website, that **isn’t** specifically data sensitive, yet requires private access.

An ideal candidate could be an administration page for entering dates or events onto a basic website.

---

## Security by Obscurity

In many ways, this solution does follow the [Security by Obscurity](<https://en.wikipedia.org/wiki/Security_through_obscurity>) model, **but** with the crucial addition of an extra layer!

A lot of web services nowadays are using the ‘complex url’ pattern of keeping a resource public, yet almost impossible to guess *(for instance, some ways of sharing documents on Microsoft *[*Oncedrive*](<https://onedrive.live.com/about/en-gb/>)*etc).*

To clarify, this is where the web address contains random characters (often appended to the end of the url), which mean absolutely nothing to the end user, but are actually a unique resource code.

**Complex URL forms the first part of this implementation.**

- Create a ‘key’ which is appended to a [query string](<https://en.wikipedia.org/wiki/Query_string>). 
- Check the query string being sent to the server, on page request, to establish whether or not to display the resource.

<!-- -->

Very basic, yet surprisingly secure(ish).

Of course, the main concern with this solution, is that whilst the web address may not be guessable, it is certainly shareable!

## Enter Secure Cookies

The crucial secondary level to this solution, is to ensure a secure cookie is present on each device you are allowing to access this web resource.

> No cookie – No access

Again, a simple principle, but surprisingly secure – indeed, let us not forget, that secure http cookies are pretty much what governs conventional web authentication processes anyway!

Of course throw it all onto port 443 (https) and you extend the security even further.

---

## The Code!

Below is an example of how this very basic process can be implemented in asp.net (c#).

**Adding cookie to the device *(also providing the ability to remove)***

<script src="https://gist.github.com/normansolutions/d7d28220fc03f03ce345.js"></script>

<noscript><a href="https://gist.github.com/d7d28220fc03f03ce345">Click for code snippet</a></noscript>

**Storing the complex query string in a web.config for easy maintenance**

<script src="https://gist.github.com/normansolutions/3740c5c29c3d637a51c0.js"></script>

<noscript><a href="https://gist.github.com/3740c5c29c3d637a51c0">Click for code snippet</a></noscript>

**Server side checking that cookie is present and query string matches**

<script src="https://gist.github.com/normansolutions/6c84c627ea9502e753eb.js"></script>

<noscript><a href="https://gist.github.com/6c84c627ea9502e753eb">Click for code snippet</a></noscript>

---



## Summary

I have used this approach on several basic web solutions, that *don’t* require armour plating security, but equally shouldn't ideally be exposed to all and sundry.

My recommendation, would be to use this on internal sites *(behind the firewall)* or small public sites. It makes life remarkably simple for updating basic content, without having to implement a full authentication system.

Indeed, one *could* argue that this is **even more secure** than some conventional username and password systems – *especially* when you often see the ridiculously hackable passwords that some end users use!

Of course, it doesn't particularly scale well, and will cause slight annoyance if you clear down your cookies; but then again, it is only intended for quick solution, niche requirements.

