# Corridor

![Swift compatibility](https://img.shields.io/badge/Swift-4.1-orange.svg)&nbsp;&nbsp;&nbsp;[![CircleCI](https://circleci.corp.nextdoor.com/gh/Nextdoor/corridor.svg?style=shield)](https://circleci.corp.nextdoor.com/gh/Nextdoor/corridor)

Spend less time writing custom URL matching and parsing logic. Define any URL format you support using a single string, and let Corridor do the heavy lifting.

Suppose you want to handle a user-profile universal-link like: `https://example.com/user/15127128`.

(1) Create a *route* -- a [Codable](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types) struct that contains all the values you want to extract from the URL. Once the URL is matched, the userId will have a value of `15127128`
```swift
struct ViewUserProfile: CorridorRoute {
    let userId: Int
}
```

(2) Register the format: `"/user/:userId{int}"`

```swift
router.register("/user/:userId{int}", { try corridorResponse($0, ViewUserProfile.self) })
```

**Now, for the usage:**

(3) Call `attemptMatch(_:URL)` with the url `https://example.com/user/15127128` to get a matched-response

```swift
let result = router.attemptMatch(url)
```

(4) Switch on the result's `route`:

```swift
let route = result.route
switch route {
  case let route as ViewUserProfile:
    print(route.userId)
  default:
    print("url not matched")
}
```
`15127128` *Voila!*


- [Overview](#overview)
- [Installation](#installation)
- [Contribute](#contribute)
- [License](#license)

## Overview

See an [example project](https://github.com/Nextdoor/example-corridor.git) using Corridor

### Route

A struct that conforms to `CorridorRoute`. Its variables correspond to values contained in a URL. It's created when a URL is matched.

### Router

Routers facilitate the process of matching a URL to a route:

```swift
let router = CorridorRouter()
```

Let's register a type of URL:

```swift
router.register("/user/:userId{int}", { try corridorResponse($0, ViewUserProfile.self) })
```
> ViewUserProfile is the struct that we defined in the first example

`"/user/:userId{int}"` is the URL format. It matches URLs that start with `/user` and have an integer value after.

`{ try corridorResponse($0, ViewUserProfile.self) }` is a block that populates the route `ViewUserProfile` if the URL is matched.

### URL format

A URL format is split into a path and a query:
- Path: includes all the URL values separated by "/"
- Query: all the key-value pairs after the URL's last "/"

> URL formats must start with a forward slash "/"

#### Formatting the path

Suppose you want to match URLs in the form `/user/12891`, that start with `user` and end with a number.

The URL format for this is: `"/user/:userId{int}"`, where the number after `user` is represented as `:userId{int}`.

Each param you want to extract follows the form `:paramName{baseType}` or `:paramName`.
- `paramName` is the same name as a variable in the route
- `baseType` indicates the type of `paramName`

So `:userId` without an explicit base type would map to `let userId: String` in a route, while `:userId{int}` would map to `let userId: Int` in a route.

> URL definitions must start with a forward slash "/"

> Base type 'string' maps to a String

> Base type 'int' maps to a Int

#### Formatting the query

Suppose you want to match URLs in the form `/user?userId=12891`, that begin with a `user` path, and have a numeric `userId` value in the params.

The URL format for this is: `"/user/?:userId{int}"`, where everything after `?` is part of the query.

**Optionals:**

Now suppose that the `userId` value was optional, so `/user&userId=12891` and `/user` would map to the same route.

The URL format for this is: `"/user/?:userId{int?}"`

**Literals:**

Now suppose that we wanted to match URLs in the form `/user&userId=12891&sourceType=email`, where the ('sourceType', 'email') pair was present in the query.

The URL format for this is: `"/user/?:userId{int}&:sourceType{'email'}"`

> URL formats must separate consecutive query params with an ampersand '&'

### Support custom base types

The URL definition `"/user/:userId{int}?:nickname{string}"` contains built-in base types: `"int"`, `"string"`, and `"bool"`.
Each base type maps to a Swift type:

`"int" -> Int`

`"string" -> String`

`"bool" -> Bool`

> Any base type can be enclosed by square brackets to represent a comma separated list of base values. Example: `"[int]" -> [Int]`.

What if you want to use a base type that isn't one of the built-in ones? Here's an example:

(1) Define a base type named "uint" that converts values to UInt:

```swift
private struct CorridorTypeUInt: CorridorTypeProtocol {
    let name = "uint"
    func convertToType(from value: String) -> Any? {
      return UInt(value)
    }
}
```

> Base type names must be alphabetic, and cannot be identical to any of the existing built-in base type names

(2) Instantiate `CorridorTypes` with the custom base type:

```swift
let baseTypes = CorridorTypes(customTypes: [CorridorTypeUInt()])
```

(3) Instantiate the router with the baseTypes

```swift
let router = CorridorRouter(corridorTypes: baseTypes)
```

**Now, for the usage:**

```swift
struct ViewUserProfile: CorridorRoute {
    let userId: UInt
    let nickname: String?
}
```

```swift
router.register("/user/:userId{uint}?:nickname{string}", { try corridorResponse($0, ViewUserProfile.self) })
```

(4) Call `attemptMatch(_:URL)` with the url `www.example.com/8971/?nickname=Bob`

```swift
let result = router.attemptMatch(url)
let route = routeResponse.route as! ViewUserProfile
print(route.userId)
```
`8971` *Voila!*


### Match *global* query params

What if a query parameter such as a tracking id, or user id is contained in many of your URLs?

Suppose your URLs contained a query param `sourceUserId` to track the user who clicked on the URL.

You could include `let sourceUserId: String?` in all your routes, but doing so is tedious and error-prone. *CorridorGlobalParams* to the rescue!

(1) Create a struct that conforms to `CorridorGlobalParams`

```swift
struct GlobalParams: CorridorGlobalParams {
  let sourceUserId: String?
}
```

(2) Create a mapping

```swift
let mapping = GlobalQueryOptionalParamsMapping(params: ["sourceUserId"],
                                                       decoder: { try corridorGlobalParamsResponse($0, GlobalParams.self) })
```

(3) Instantiate the router with the mapping

```swift
let router = CorridorRouter(globalQueryOptionalParamsMapping: mapping)
```

**Now, for the usage:**

(4) Call `attemptMatch(_:URL)` with the url `www.example.com/news_feed/?sourceUserId=abc123`

```swift
let result = router.attemptMatch(url)
let globalParams = routeResponse.globalParams as! GlobalParams
print(globalParams.sourceUserId)
```
`abc123` *Voila!*


## Installation
Corridor supports multiple methods for installing the library in a project.

### CocoaPods

To integrate Corridor into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Corridor','~> 0.0.1'
```

Also include on a separate line in your `Podfile`:

```ruby
use_frameworks!
```

### Carthage

To integrate Corridor into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "Nextdoor/corridor" ~> 0.0.1'
```

Run `carthage` to build the framework and drag the built `Corridor.framework` into your Xcode project.

### Swift Package Manager

To integrate Corridor into your Xcode project using Swift Package Manager, add it to the `dependencies` value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Nextdoor/corridor.git", from: "0.0.1")
]
```

## Contribute

- If you have a feature request or discover a bug, open an issue
- If you'd like to contribute changes, submit a pull request

## License

Corridor is released under the Apache 2.0 license. [See LICENSE](https://github.com/Nextdoor/corridor/blob/master/LICENSE) for details.
