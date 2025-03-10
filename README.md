ResearchKit Framework
===========

> [!NOTE]  
> This repository is a [StanfordBDHG](https://github.com/StanfordBDHG) fork of the [ResearchKit project](https://github.com/ResearchKit/ResearchKit) by Apple, adding support for:
> - The [Swift Package Manager](https://www.swift.org/documentation/package-manager/) by building ResearchKit to an [XCFramework](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle) via GitHub Actions and exposing the built XCFramework as a SPM binary target to speed up build times of projects / packages consuming our ResearchKit fork.
> - SwiftUI support to easily interact with the `ORKTaskViewController` using the [`ORKOrderedTaskView`](https://swiftpackageindex.com/stanfordbdhg/researchkit/documentation/researchkitswiftui/orkorderedtaskview).
> - Building ResearchKit with enabled [Swift's C++ Interoperability](https://www.swift.org/documentation/cxx-interop/), requiring minor code adjustments (not additive) to the ResearchKit codebase.
> - Building ResearchKit natively on [visionOS to run on Apple Vision Pro](https://developer.apple.com/visionos/).

[![Create XCFramework and Release](https://github.com/StanfordBDHG/ResearchKit/actions/workflows/release.yml/badge.svg)](https://github.com/StanfordBDHG/ResearchKit/actions/workflows/release.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FResearchKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordBDHG/ResearchKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FResearchKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordBDHG/ResearchKit)
[![License](https://img.shields.io/badge/license-BSD-green.svg?style=flat)](https://github.com/ResearchKit/ResearchKit#license)


The *ResearchKit™ framework* is an open source software framework that makes it easy to create apps
for medical research or for other research projects.

* [Getting Started](#gettingstarted)
* [Documentation](docs/)
* [Best Practices](https://github.com/ResearchKit/ResearchKit/wiki/best-practices)
* [Contributing to ResearchKit](CONTRIBUTING.md)
* [Website](https://www.researchandcare.org)
* [ResearchKit BSD License](#license)

Getting More Information
========================

* Join the [*ResearchKit* Forum](https://developer.apple.com/forums/tags/researchkit) for discussing uses of the *ResearchKit framework and* related projects.

Use Cases
===========

A task in the *ResearchKit framework* contains a set of steps to present to a user. Everything,
whether it’s a *survey*, the *consent process*, or *active tasks*, is represented as a task that can
be presented with a task view controller.

Surveys
-------

The *ResearchKit framework* provides a pre-built user interface for surveys, which can be presented
modally on an *iPhone*, *iPod Touch*, or *iPad*. See
 *[Creating Surveys](docs/Survey/)* for more
 information.


Consent
----------------

The *ResearchKit framework* provides visual consent templates that you can customize to explain the
details of your research study and obtain a signature if needed.
See *[Obtaining Consent](docs/InformedConsent/)* for
more information.


Active Tasks
------------

Some studies may need data beyond survey questions or the passive data collection capabilities
available through use of the *HealthKit* and *CoreMotion* APIs if you are programming for *iOS*.
*ResearchKit*'s active tasks invite users to perform activities under semi-controlled conditions,
while *iPhone* sensors actively collect data. See
*[Active Tasks](docs/ActiveTasks/)* for more
information.
ResearchKit active tasks are not diagnostic tools nor medical devices of any kind and output from those active tasks may not be used for diagnosis. Developers and researchers are responsible for complying with all applicable laws and regulations with respect to further development and use of the active tasks.

Charts
------------
*ResearchKit* includes a *Charts module*. It features three chart types: a *pie chart* (`ORKPieChartView`), a *line graph chart* (`ORKLineGraphChartView`), and a *discrete graph chart* (`ORKDiscreteGraphChartView`).

The views in the *Charts module* can be used independently of the rest of *ResearchKit*. They don't automatically connect with any other part of *ResearchKit*: the developer has to supply the data to be displayed through the views' `dataSources`, which allows for maximum flexibility.


Getting Started<a name="gettingstarted"></a>
===============


Requirements
------------

The primary *ResearchKit framework* codebase supports *iOS* and requires *Xcode 8.0* or newer. The
*ResearchKit framework* has a *Base SDK* version of *8.0*, meaning that apps using the *ResearchKit
framework* can run on devices with *iOS 8.0* or newer.

Integrating the ResearchKit framework using the [Swift Package Manager](https://www.swift.org/package-manager/) requires Xcode 15.0 and Swift 5.9 or newer.

Note: You can also import *ResearchKit* into your project using a
 [alternative installation](./docs-standalone/alternative-installation.md) such as *CocoaPods*, *Carthage*, or as a dynamic framework using previous Xcode versions.

Adding the ResearchKit framework to your App
------------------------------

This walk-through shows how to embed the *ResearchKit framework* in your app using the [Swift Package Manager](https://www.swift.org/package-manager/),
and present a simple task view controller.

### 1. Add the ResearchKit framework to Your Project

Follow the article about [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) using the following repository URL: `https://github.com/StanfordBDHG/ResearchKit`.

### 2. Create a Step

In this walk-through, we will use the *ResearchKit framework* to modally present a simple
 single-step task showing a single instruction.

Create a step for your task by adding some code, perhaps in `viewDidAppear:` of an existing view
controller. To keep things simple, we'll use an instruction step (`ORKInstructionStep`) and name
the step `myStep`.

*Objective-C*

```objc
ORKInstructionStep *myStep =
  [[ORKInstructionStep alloc] initWithIdentifier:@"intro"];
myStep.title = @"Welcome to ResearchKit";
```

*Swift*

```swift
let myStep = ORKInstructionStep(identifier: "intro")
myStep.title = "Welcome to ResearchKit"
```

### 3. Create a Task

Use the ordered task class (`ORKOrderedTask`) to create a task that contains `myStep`. An ordered
task is just a task where the order and selection of later steps does not depend on the results of
earlier ones. Name your task `task` and initialize it with `myStep`.

*Objective-C*

```objc
ORKOrderedTask *task =
  [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:@[myStep]];
```

*Swift*

```swift
let task = ORKOrderedTask(identifier: "task", steps: [myStep])
```

### 4. Present the Task

Create a task view controller (`ORKTaskViewController`) and initialize it with your `task`. A task
view controller manages a task and collects the results of each step. In this case, your task view
controller simply displays your instruction step.

*Objective-C*

```objc
ORKTaskViewController *taskViewController =
  [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
taskViewController.delegate = self;
[self presentViewController:taskViewController animated:YES completion:nil];
```

*Swift*

```swift
let taskViewController = ORKTaskViewController(task: task, taskRun: nil)
taskViewController.delegate = self
present(taskViewController, animated: true, completion: nil)
```

The above snippet assumes that your class implements the `ORKTaskViewControllerDelegate` protocol.
This has just one required method, which you must implement in order to handle the completion of
 the task:

*Objective-C*

```objc
- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error {

    ORKTaskResult *taskResult = [taskViewController result];
    // You could do something with the result here.

    // Then, dismiss the task view controller.
    [self dismissViewControllerAnimated:YES completion:nil];
}
```

*Swift*

```swift
func taskViewController(_ taskViewController: ORKTaskViewController, 
                didFinishWith reason: ORKTaskViewControllerFinishReason, 
                                    error: Error?) {
    let taskResult = taskViewController.result
    // You could do something with the result here.

    // Then, dismiss the task view controller.
    dismiss(animated: true, completion: nil)
}
```


If you now run your app, you should see your first *ResearchKit framework* instruction step:

<center>
<figure>
  <img src="https://github.com/ResearchKit/ResearchKit/wiki/HelloWorld.png" width="50%" alt="HelloWorld example screenshot" align="middle"/>
</figure>
</center>



What else can the ResearchKit framework do?
-----------------------------

The *ResearchKit* [`ORKCatalog`](samples/ORKCatalog) sample app is a good place to start. Find the
project in ResearchKit's [`samples`](samples) directory. This project includes a list of all the
types of steps supported by the *ResearchKit framework* in the first tab, and displays a browser for the
results of the last completed task in the second tab. The third tab shows some examples from the *Charts module*.



License<a name="license"></a>
=======

The source in the *ResearchKit* repository is made available under the following license unless
another license is explicitly identified:

```
Copyright (c) 2015 - 2018, Apple Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
