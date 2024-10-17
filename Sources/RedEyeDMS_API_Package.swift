// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation


@available(iOS 13.0.0, *)
class RedEyeNetworkManager {
    var baseURL = "https://api.redeyedms.com"
    
    //Get request to retrieve list of all bucket groups
    func getGroups(apiToken: String) async throws -> [String] {
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
    func getMetadataFields(apiToken: String) async throws -> [String] {
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
            let d = try decoder.decode([BucketMetadata].self, from: data)
            var array: [String] = []
            for x in d {
                array.append(x.name)
            }
            return array
        } catch {
            throw apiError.invalidData
        }
    }

    func uploadNewFile(file: File, apiToken: String) async throws -> [String] {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = buildBody(fileMetadata: file, boundary: boundary)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v2/upload")!,timeoutInterval: Double.infinity)
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = body
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        
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
            //Need to build model for artefact data and add this model to this decoder.decode
            let d = try decoder.decode([BucketMetadata].self, from: data)
            var array: [String] = []
            for x in d {
                array.append(x.name)
            }
            return array
        } catch {
            throw apiError.invalidData
        }
        
    }
    
    func buildBody(fileMetadata: File, boundary: String) -> Data {
        
        //Build parameters
        var parameter = [[
            "key": "file",
            "src": fileMetadata.filepath,
            "type": "file"
        ],
        [
            "key": "data",
            "value": "{\"type\": \"\(fileMetadata.artefactType)\",\"artefactHash\": {\"md5\": \"\(fileMetadata.sha256.lowercased())\",\"sha256\": \"\(fileMetadata.sha256.lowercased())\"},\"fileHash\": \"\(fileMetadata.sha256.lowercased())\",\"metadata\": [{\"name\": \"DRAWING_NUM\",\"value\": [\"\(fileMetadata.filepath)\"]},{\"name\": \"targetGroup\",\"value\": [\"\(fileMetadata.targetGroup)\"]}]}",
            "type": "text"
        ]]
        
        //Build data body
        var body = Data()
        
        for p in parameter {
            let paramName = p["key"]! //Initial key read
            
            body += Data("--\(boundary)\r\n".utf8)
            body += Data("Content-Disposition:form-data; name=\"\(paramName)\"".utf8) //First line for the new key
            
            let paramType = p["type"]
            
            if paramType == "file" {
                let paramSrc = p["src"]
                let url = URL(fileURLWithPath: paramSrc ?? "")
                guard let fileContent = try? Data(contentsOf: url) else {
                    print("failed")
                    return Data()
                }
                body += Data("; filename=\"\(String(describing: paramSrc))\"\r\n".utf8)
                body += Data("Content-Type: content-type header\r\n".utf8)
                body += Data("\r\n".utf8)
                body += fileContent
                body += Data("\r\n".utf8)
            } else {
                body += Data("\r\nContent-Type: text/plain".utf8)
                let paramValue = p["value"]
                body += Data("\r\n\r\n\(String(describing: paramValue))\r\n".utf8)
            }
        }
        
        body += Data("--\(boundary)--\r\n".utf8)
        
        return body
    }

}
