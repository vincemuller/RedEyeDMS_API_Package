// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation


@available(iOS 13.0.0, *)
@available(macOS 12.0.0, *)
public class RedEyeNetworkManager {
    public init() {}
    var baseURL = "https://api.redeyedms.com"
    
    //Get request to retrieve list of all bucket groups
    public func getGroups(apiToken: String) async throws -> [String] {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/groups")!,timeoutInterval: Double.infinity)
        
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            do {
                let decoder = JSONDecoder()
                let d = try decoder.decode(Errors.self, from: data)
                var errors: [String] = []
                for x in d.errors {
                    errors.append(x.error)
                }
                return errors
            } catch {
                return ["Data handling error"]
            }
        }
        
        do {
            let decoder = JSONDecoder()
            let groups = try decoder.decode([Group].self, from: data)
            var array: [String] = []
            for x in groups {
                array.append(x.name)
            }
            return array
        } catch {
            throw apiError.invalidData
        }
    }
    
    //Get request to retrive list of all bucket metadata field names and descriptions
    public func getMetadataFields(apiToken: String) async throws -> [String] {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/metadata")!,timeoutInterval: Double.infinity)
        
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            do {
                let decoder = JSONDecoder()
                let d = try decoder.decode(Errors.self, from: data)
                var errors: [String] = []
                for x in d.errors {
                    errors.append(x.error)
                }
                return errors
            } catch {
                return ["Data handling error"]
            }
        }
        
        do {
            let decoder = JSONDecoder()
            let d = try decoder.decode([Metadata].self, from: data)
            var array: [String] = []
            for x in d {
                array.append(x.name)
            }
            return array
        } catch {
            throw apiError.invalidData
        }
    }
    
    
    func buildParameters(record: Record) -> [[String:Any]] {
        return [[
            "key": "file",
            "src": record.filepath,
            "type": "file"
        ],
                [
                    "key": "data",
                    "value": "{\"type\": \"\(record.artefactType)\",\"artefactHash\": {\"md5\": \"\(record.sha256.lowercased())\",\"sha256\": \"\(record.sha256.lowercased())\"},\"fileHash\": \"\(record.sha256.lowercased())\",\"metadata\": [{\"name\": \"DRAWING_NUM\",\"value\": [\"\(record.filepath)\"]},{\"name\": \"targetGroup\",\"value\": [\"\(record.targetGroup)\"]}]}",
                    "type": "text"
                ]] as [[String: Any]]
    }
    
    func buildBody(parameter: [String: Any], b: Data, boundary: String) -> Data {
        var body = b
        let paramName = parameter["key"]! //Initial key read
        
        body += Data("--\(boundary)\r\n".utf8)
        
        body += Data("Content-Disposition:form-data; name=\"\(paramName)\"".utf8) //First line for the new key
        
        let paramType = parameter["type"] as! String
        
        if paramType == "file" {
            let paramSrc = parameter["src"] as! String
            let url = URL(fileURLWithPath: paramSrc)
            guard let fileContent = try? Data(contentsOf: url) else {
                print("failed")
                return Data()
            }
            body += Data("; filename=\"\(paramSrc)\"\r\n".utf8)
            body += Data("Content-Type: content-type header\r\n".utf8)
            body += Data("\r\n".utf8)
            body += fileContent
            body += Data("\r\n".utf8)
        } else {
            body += Data("\r\nContent-Type: text/plain".utf8)
            let paramValue = parameter["value"] as! String
            body += Data("\r\n\r\n\(paramValue)\r\n".utf8)
        }
        return body
    }
    
    public func uploadRequest(record: Record, apiToken: String) {
        
        let parameters = buildParameters(record: record)
        
        var body = Data()
        let boundary = "Boundary-\(UUID().uuidString)"
        
        for param in parameters {
            autoreleasepool {
                body = buildBody(parameter: param, b: body, boundary: boundary)
            }
        }
        
        body += Data("--\(boundary)--\r\n".utf8)
        
        var request = URLRequest(url: URL(string: "https://api.redeyedms.com/api/v2/upload")!,timeoutInterval: Double.infinity)
        //d7ec475b45d3857d171a283e336ed6cc77d14c835943747a9ceec549e0f0b6ef <- Vincent's Artefacts API Token for Testing
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("AWSALB=aEwxWhSOtuTdKHEy/3Clb5ZlNZCM3r+30xGONZyni8V+AdqkCLrQmFRmD2m2CK2hRsC3rjdvDE9mLMJ+wq5bCrHdvrxcvhR5iPI/v3LXx2LN0awo9NhCMkEs2IPu; AWSALBCORS=aEwxWhSOtuTdKHEy/3Clb5ZlNZCM3r+30xGONZyni8V+AdqkCLrQmFRmD2m2CK2hRsC3rjdvDE9mLMJ+wq5bCrHdvrxcvhR5iPI/v3LXx2LN0awo9NhCMkEs2IPu", forHTTPHeaderField: "Cookie")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        //            request.httpBody = body
        
        //            sessionFunc(request: request, session: session, queue: operationQueue, count: count)
        let session = URLSession(configuration: .ephemeral)
        
        sessionFunc2(request: request, body: body, session: session) { result in
            switch result {
            case .success(let data):
                print("success!")
            case .failure(let error):
                print("Error: \(error)")
                return
            }
        }
        body = Data()
    }
}

func sessionFunc2(request: URLRequest, body: Data, session: URLSession, completed: @escaping (Result<[Data], Error>) -> Void) {
    var task = URLSessionTask()
    
    task = session.uploadTask(with: request, from: body) { data, response, error in
        
        if let error = error {
            completed(.failure(error))
            print("Session func : \(error.localizedDescription)")
            return
        }
        
        //        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        //            let error = error
        //            completed(.failure())
        //            return
        //        }
        
        if var response = response as? HTTPURLResponse {
            print("Response: \(response.statusCode)")
            
            if response.statusCode == 200 {
                successfullyUploaded += 1
            }
            
            //            if count == 150 {
            //                queue.signal()
            //            }
            //            task.cancel()
            //            session.invalidateAndCancel()
        }
        
        let d2 = data
        
        do {
            let decoder = JSONDecoder()
            let d = try decoder.decode(Errors.self, from: d2 ?? Data())
            print(d)
        } catch {
            print("Data coding issue")
            return
        }
    }
    
    task.resume()
    
    //        if count == 150 {
    //            _ = queue.wait(timeout: DispatchTime.distantFuture)
    //        }
}

var successfullyUploaded: Int = 0
