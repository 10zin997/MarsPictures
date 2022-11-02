/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI
import OSLog

class MarsData{
  let marsRoverAPI = MarsRoverAPI()
  
  // nasa might launch new rovers, so we need to request any and all rovers from nasa, unlike how we manually did.
  func fetchAllRovers() async -> [Rover]{
    do{
      return try await marsRoverAPI.allRovers()
    }catch{
      log.error("error fetching rovers: \(String(describing: error))")
      return []
    }
  }
  
  func fetchLatestPhotos() async -> [Photo]{
    
    await withTaskGroup(of: Photo?.self){ group in
      let rovers = await fetchAllRovers()
      //loop through each rover
      for rover in rovers {
        //call the addTask(prioerity:operation:) on the group and pass a closure representing the work the task needs to perform
        group.addTask {
          //wait for all the latest photos from each rover to be downloaded
          let photos = try? await self.marsRoverAPI.latestPhotos(rover: rover)
            // return the first photo if there is none return nil
          return photos?.first
        }
      }
      var latestPhotos: [Photo] = []
      for await result in group{
        if let photo = result{
          latestPhotos.append(photo)
        }
      }
      return latestPhotos
    }
    
  }
  
  // to see all the rovers and each of their photos
  func fetchPhotoManifests() async throws -> [PhotoManifest]{
    
    return try await withThrowingTaskGroup(of: PhotoManifest.self){ group in
      let rovers = await fetchAllRovers()
      try Task.checkCancellation()
      for rover in rovers {
        group.addTask{
          return try await self.marsRoverAPI.photoManifest(rover: rover)
        }
      }
      return try await group.reduce(into: []){ manifestArray, manifest in
        manifestArray.append(manifest)
      }
    }
  }
  func fetchPhotos(roverName: String, sol: Int) async -> [Photo]{
    do{
      return try await marsRoverAPI.photos(roverName: roverName, sol: sol)
      
    }catch{
      log.error("Error fetching rover Phots : \(String(describing: error))")
      return []
    }
  }
  
}
