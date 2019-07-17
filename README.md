# Resource Encoder
A script to encode project resources as byte arrays. Swift only, but feel free to add your own languages.

## Why?
When developing mobile apps, there are many cases where you shouldn't have certain strings as literals in your binary (or, even worse, have them in resource files). For example, an API key stored as a string in your code could easily be retrieved by hackers and used to your detriment.

## How?
Encoding strings as byte-arrays makes identifying them in your binary much more difficult. This script takes an input file and generates a class that will give you easy access and secure access to the content of the file at runtime. There are two ways you can use this.

### Single file

Given the file `APIKey.txt` that contains the string `Abcd123`, run:

```bash
$ resource-encoder.sh APIKey.txt APIKey.swift
```

This generates `APIKey.swift` containing the following:

```swift
import Foundation

struct APIKey {

    static func string() -> String {
        return String(data: data(), encoding: .ascii)!
    }

    static func data() -> Data {
        var bytes = self.bytes()
        bytes.removeLast()
        return Data(bytes: bytes, count: bytes.count)
    }

    // Contains an extra 0x0 at the end to prevent reading of the array running into random memory
    private static func bytes() -> [UInt8] {
        return [0x41, 0x62, 0x63, 0x64, 0x31, 0x32, 0x33, 0x0a, 0x0]
    }
}
```

### Multiple files
In an Xcode Runscript Build Phase, run `bash /path/to/resource-encoder.sh`. The script will use the input and output files for generation.
For example, in a command-line app I am building, I want to bundle some resources for use at runtime. This isn't possible by default, so `resource-encoder.sh` helps me:
![Example](/img/runscript.png?raw=true "Assuming the script is in the root directory of your Xcode project")

**Ensure that input files are NOT in your target's membership - that would defeat the purpose of this entirely!** 

## What's next?
If you want to support Android, feel free to make a PR. I'd suggest something like using a flag like `--kotlin` to identify the output language.
