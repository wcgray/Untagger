# Untagger

Untagger is a removal and full text extraction of HTML written in Swift heavily inspired by <a href="https://github.com/kohlschutter/boilerpipe">Boilerpipe</a>.

## Usage

```swift
UntaggerManager.sharedInstance.getText(url: url) { [weak self] (title, body, source, error) in
            if error == nil {
                print("Article title: \(title!)")
                print("Article body: \(body!)")
            }

            if let error = error {
                print("Error: \(error.message)")
            }
        }
```

## License

MIT
