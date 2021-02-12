import Foundation

public protocol FileManaging {

    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey: Any]?) -> Bool
    func moveItem(at url: URL, to: URL) throws

    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    func fileExists(atPath: String) -> Bool

    func createFileHandle(forWritingToURL: URL) throws -> FileHandle

    func read(contentsOf url: URL) throws -> String
    @discardableResult
    func write(dictionary: [String: Any], to url: URL, atomically: Bool) -> Bool
    func write(data: Data, to url: URL, options: Data.WritingOptions) throws

    func read(dictionaryAt url: URL) -> [String: Any]?

    func data(forURL url: URL) -> Data?
    func isDeletableFile(atURL url: URL) -> Bool

    func removeItem(at URL: URL) throws

    func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask) throws -> URL

    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
    func copyItem(at srcURL: URL, to dstURL: URL) throws

    func setResourceValues(_ values: URLResourceValues, at url: inout URL) throws

}

extension FileManager: FileManaging {
    public func write(data: Data, to url: URL, options: Data.WritingOptions) throws {
        try data.write(to: url, options: options)
    }

    public func createFileHandle(forWritingToURL: URL) throws -> FileHandle {
        return try FileHandle(forWritingTo: forWritingToURL)
    }

    public func read(contentsOf url: URL) throws -> String {
        return try String(contentsOf: url, encoding: String.Encoding.utf8)
    }

    public func write(dictionary: [String: Any], to url: URL, atomically: Bool) -> Bool {
        return (dictionary as NSDictionary).write(to: url as URL, atomically: atomically)
    }

    public func read(dictionaryAt url: URL) -> [String: Any]? {
        return NSDictionary(contentsOf: url as URL) as? [String: Any]
    }

    public func data(forURL url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }

    public func isDeletableFile(atURL url: URL) -> Bool {
        return isDeletableFile(atPath: url.path)
    }

    public func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask) throws -> URL {
        return try url(for: directory, in: domain, appropriateFor: nil, create: true)
    }

    public func setResourceValues(_ values: URLResourceValues, at url: inout URL) throws {
        try url.setResourceValues(values)
    }
}
