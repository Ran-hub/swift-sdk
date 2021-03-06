import XCTest
import ConfigCat

class LazyLoadingAsyncTests: XCTestCase {
    
    func testGet() {
        let mockSession = MockURLSession()
        mockSession.enqueueResponse(response: Response(body: "test", statusCode: 200))
        mockSession.enqueueResponse(response: Response(body: "test2", statusCode: 200, delay: 2))
        
        let fetcher = ConfigFetcher(session: mockSession, apiKey: "")
        let policy = LazyLoadingPolicy(cache: InMemoryConfigCache(), fetcher: fetcher, cacheRefreshIntervalInSeconds: 5, useAsyncRefresh: true)
        
        XCTAssertEqual("test", try policy.getConfiguration().get())
        XCTAssertEqual("test", try policy.getConfiguration().get())
        
        //wait for cache invalidation
        sleep(6)
        
        //previous value returned until the new is not fetched
        XCTAssertEqual("test", try policy.getConfiguration().get())
        
        //wait for refresh response
        sleep(3)
        
        //new value is present
        XCTAssertEqual("test2", try policy.getConfiguration().get())
    }
    
    func testGetFailedRefresh() {
        let mockSession = MockURLSession()
        mockSession.enqueueResponse(response: Response(body: "test", statusCode: 200))
        mockSession.enqueueResponse(response: Response(body: "test2", statusCode: 500, delay: 2))
        
        let fetcher = ConfigFetcher(session: mockSession, apiKey: "")
        let policy = LazyLoadingPolicy(cache: InMemoryConfigCache(), fetcher: fetcher, cacheRefreshIntervalInSeconds: 5, useAsyncRefresh: true)
        
        XCTAssertEqual("test", try policy.getConfiguration().get())
        XCTAssertEqual("test", try policy.getConfiguration().get())
        
        //wait for cache invalidation
        sleep(6)
        
        //previous value returned until the new is not fetched
        XCTAssertEqual("test", try policy.getConfiguration().get())
        
        //wait for refresh response
        sleep(1)
        
        //new value is present
        XCTAssertEqual("test", try policy.getConfiguration().get())
    }
}
