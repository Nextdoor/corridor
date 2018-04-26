
import CorridorExample
import XCTest

class URLRouterTest: XCTestCase {

    var router: URLRouter!

    override func setUp() {
        super.setUp()

        self.router = URLRouter.shared
    }

    func testGlobalParams() {
        var url = URL(string: "https://nextdoor-test.com/news_feed")!
        var globalParams = router.attemptMatch(url: url)?.globalParams as! GlobalParams
        XCTAssertNil(globalParams.emailReceiverId)
        XCTAssertNil(globalParams.emailId)

        url = URL(string: "https://nextdoor-test.com/news_feed/?action_source_user_id=123")!
        globalParams = router.attemptMatch(url: url)?.globalParams as! GlobalParams
        XCTAssertEqual(globalParams.emailReceiverId!, 123)
        XCTAssertNil(globalParams.emailId)

        url = URL(string: "https://nextdoor-test.com/news_feed/?action_source_user_id=456")!
        globalParams = router.attemptMatch(url: url)?.globalParams as! GlobalParams
        XCTAssertEqual(globalParams.emailReceiverId!, 456)
        XCTAssertNil(globalParams.emailId)

        url = URL(string: "https://nextdoor-test.com/news_feed?action_source_user_id=123&ct=23jg23i1")!
        globalParams = router.attemptMatch(url: url)?.globalParams as! GlobalParams
        XCTAssertEqual(globalParams.emailReceiverId!, 123)
        XCTAssertEqual(globalParams.emailId!, "23jg23i1")
    }

    func testViewPost() {
        var url = URL(string: "https://nextdoor-test.com/news_feed/?post=17200315")!
        var result = router.attemptMatch(url: url)?.route as! ViewPost
        XCTAssertEqual(result.postId, 17200315)
        XCTAssertNil(result.unsubscribe)

        url = URL(string: "https://nextdoor-test.com/news_feed/?post=17200315&unsub=1")!
        result = router.attemptMatch(url: url)?.route as! ViewPost
        XCTAssertEqual(result.postId, 17200315)
        XCTAssertTrue(result.unsubscribe!)
    }

    func testThankPost() {
        let url = URL(string: "https://nextdoor-test.com/like_post/17200365")!
        let result = router.attemptMatch(url: url)?.route as! ThankPost
        XCTAssertEqual(result.postId, 17200365)
    }

    func testLikeComment() {
        let url = URL(string: "https://nextdoor-test.com/like_comment/27383625/?post=17200315")!
        let result = router.attemptMatch(url: url)?.route as! LikeComment
        XCTAssertEqual(result.commentId, 27383625)
        XCTAssertEqual(result.postId, 17200315)
    }

    func testPrivateMessageUser() {
        let url = URL(string: "https://nextdoor-test.com/news_feed/?post=17200315&message_to=5854620")!
        let result = router.attemptMatch(url: url)?.route as! PrivateMessageUser
        XCTAssertEqual(result.postId, 17200315)
        XCTAssertEqual(result.recipientId, 5854620)
    }

    func testViewNewsFeed() {
        let url = URL(string: "https://nextdoor-test.com/news_feed")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewNewsFeed)
    }

    func testViewProfile() {
        let url = URL(string: "https://nextdoor-test.com/profile/7546975")!
        let result = router.attemptMatch(url: url)?.route as! ViewProfile
        XCTAssertEqual(result.profileId, 7546975)
    }

    func testViewProfileCurrentUser() {
        let url = URL(string: "https://nextdoor-test.com/profile")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewProfileCurrentUser)
    }

    func testViewEmailSettings() {
        let url = URL(string: "https://nextdoor-test.com/email_prefs/?token=UZU2Ec")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewEmailSettings)
    }

    func testViewChatConversation() {
        let url = URL(string: "https://nextdoor-test.com/inbox/15bfc2af-68a5-46de-aebe-51cdfd3ee0af")!
        let result = router.attemptMatch(url: url)?.route as! ViewChatConversation
        XCTAssertEqual(result.chatId, "15bfc2af-68a5-46de-aebe-51cdfd3ee0af")
    }

    func testViewEvent() {
        let url = URL(string: "https://nextdoor-test.com/events/443585")!
        let result = router.attemptMatch(url: url)?.route as! ViewEvent
        XCTAssertEqual(result.eventId, 443585)
    }

    func testViewGroup() {
        let url = URL(string: "https://nextdoor-test.com/groups/13578686")!
        let result = router.attemptMatch(url: url)?.route as! ViewGroup
        XCTAssertEqual(result.groupId, 13578686)
    }

    func testViewRecommendationsFavorites() {
        var url = URL(string: "https://nextdoor-test.com/favorites")!
        var result = router.attemptMatch(url: url)?.route
        XCTAssertTrue(result is ViewRecommendationsFavorites)

        url = URL(string: "https://nextdoor-test.com/recommendations/winners")!
        result = router.attemptMatch(url: url)?.route
        XCTAssertTrue(result is ViewRecommendationsFavorites)
    }

    func testRecommendBusiness() {
        let url = URL(string: "https://nextdoor-test.com/recommend_business")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is RecommendBusiness)
    }

    func testViewBusinessCategoryDetail() {
        var url = URL(string: "https://nextdoor-test.com/topic/1")!
        var result = router.attemptMatch(url: url)?.route as! ViewBusinessCategoryDetail
        XCTAssertEqual(result.topicId, 1)
        XCTAssertNil(result.recommend)

        url = URL(string: "https://nextdoor-test.com/topic/1?recommend=1")!
        result = router.attemptMatch(url: url)?.route as! ViewBusinessCategoryDetail
        XCTAssertEqual(result.topicId, 1)
        XCTAssertTrue(result.recommend!)
    }

    func testViewNeighborhoodMap() {
        let url = URL(string: "https://nextdoor-test.com/map")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewNeighborhoodMap)
    }

    func testSendInvite() {
        var url = URL(string: "https://nextdoor-test.com/invitation_email")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is SendInvite)

        url = URL(string: "https://nextdoor-test.com/invitation_postcards")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is SendInvite)
    }

    func testViewRealEstateSection() {
        let url = URL(string: "https://nextdoor-test.com/real-estate")!

        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewRealEstateSection)
    }

    func testViewRealEstateListing() {
        let url = URL(string: "https://nextdoor-test.com/real-estate-listings/1234")!

        let result = router.attemptMatch(url: url)?.route as! ViewRealEstateListing
        XCTAssertEqual(result.listingId, 1234)
    }

    func testViewClassifiedItem() {
        let url = URL(string: "https://nextdoor-test.com/for_sale_and_free/e38e034d-46af-49f5-9390-092f535c428e/" +
            "?init_source=digest")!
        let result = router.attemptMatch(url: url)?.route as! ViewClassifiedItem
        XCTAssertEqual(result.classifiedId, "e38e034d-46af-49f5-9390-092f535c428e")
        XCTAssertEqual(result.initSource!, "digest")
    }

    func testViewClassifiedSectionMultipleFilters() {
        let urlAllParams = URL(string: "https://nextdoor-test.com/for_sale_and_free?init_source=digest&is_free=true&discounted_items_only=true")!
        let resultAllParams = router.attemptMatch(url: urlAllParams)?.route as! ViewClassifiedSection
        XCTAssertEqual(resultAllParams.initSource!, "digest")
        XCTAssertEqual(resultAllParams.discounted, true)
        XCTAssertEqual(resultAllParams.isFree, true)
        XCTAssertNil(resultAllParams.sortOrder)
        XCTAssertNil(resultAllParams.audienceType)
        XCTAssertNil(resultAllParams.topicId)
    }

    func testViewClassifiedSectionFreeItems() {
        let url = URL(string: "https://nextdoor-test.com/for_sale_and_free?init_source=digest&is_free=true")!
        let result = router.attemptMatch(url: url)?.route as! ViewClassifiedSection
        XCTAssertEqual(result.initSource!, "digest")
        XCTAssertNil(result.discounted)
        XCTAssertEqual(result.isFree, true)
        XCTAssertNil(result.sortOrder)
        XCTAssertNil(result.audienceType)
        XCTAssertNil(result.topicId)
    }

    func testViewClassifiedSectionDiscountedOnly() {
        let urlDiscounted = URL(string: "https://nextdoor-test.com/for_sale_and_free?init_source=digest&discounted_items_only=true")!
        let resultDiscounted = router.attemptMatch(url: urlDiscounted)?.route as! ViewClassifiedSection
        XCTAssertEqual(resultDiscounted.initSource!, "digest")
        XCTAssertEqual(resultDiscounted.discounted, true)
        XCTAssertNil(resultDiscounted.isFree)
        XCTAssertNil(resultDiscounted.sortOrder)
        XCTAssertNil(resultDiscounted.audienceType)
        XCTAssertNil(resultDiscounted.topicId)
    }

    func testViewClassifiedSectionSortOrder() {
        let urlAllParams = URL(string: "https://nextdoor-test.com/for_sale_and_free?init_source=digest&sort_order=2")!
        let resultAllParams = router.attemptMatch(url: urlAllParams)?.route as! ViewClassifiedSection
        XCTAssertEqual(resultAllParams.initSource!, "digest")
        XCTAssertNil(resultAllParams.discounted)
        XCTAssertNil(resultAllParams.isFree)
        XCTAssertEqual(resultAllParams.sortOrder, 2)
        XCTAssertNil(resultAllParams.audienceType)
        XCTAssertNil(resultAllParams.topicId)
    }

    func testViewClassifiedSectionAudienceType() {
        let urlAllParams = URL(string: "https://nextdoor-test.com/for_sale_and_free?init_source=digest&audience_type=8")!
        let resultAllParams = router.attemptMatch(url: urlAllParams)?.route as! ViewClassifiedSection
        XCTAssertEqual(resultAllParams.initSource!, "digest")
        XCTAssertNil(resultAllParams.discounted)
        XCTAssertNil(resultAllParams.isFree)
        XCTAssertNil(resultAllParams.sortOrder)
        XCTAssertEqual(resultAllParams.audienceType, 8)
        XCTAssertNil(resultAllParams.topicId)
    }

    func testViewClassifiedSectionTopicFilter() {
        let urlAllParams = URL(string: "https://nextdoor-test.com/for_sale_and_free?init_source=digest&topic_ids=7")!
        let resultAllParams = router.attemptMatch(url: urlAllParams)?.route as! ViewClassifiedSection
        XCTAssertEqual(resultAllParams.initSource!, "digest")
        XCTAssertNil(resultAllParams.discounted)
        XCTAssertNil(resultAllParams.isFree)
        XCTAssertNil(resultAllParams.sortOrder)
        XCTAssertNil(resultAllParams.audienceType)
        XCTAssertEqual(resultAllParams.topicId, 7)
    }

    func testViewRecommendations() {
        let url = URL(string: "https://nextdoor-test.com/recommendations")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewRecommendations)
    }

    func testTagRecommendations() {
        var url = URL(string: "https://nextdoor-test.com/tag_replies")!
        var result = router.attemptMatch(url: url)?.route
        XCTAssertTrue(result is TagRecommendations)

        url = URL(string: "https://nextdoor-test.com/recommendations/tag")!
        result = router.attemptMatch(url: url)?.route
        XCTAssertTrue(result is TagRecommendations)
    }

    func testViewRecommendationsAllTopics() {
        let url = URL(string: "https://nextdoor-test.com/recommendations/all_topics")!
        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewRecommendationsAllTopics)
    }

    func testViewChannelsSection() {
        let url = URL(string: "https://nextdoor-test.com/channels")!

        XCTAssertTrue(router.attemptMatch(url: url)?.route is ViewChannelsSection)
    }

    func testViewChannel() {
        let url = URL(string: "https://nextdoor-test.com/channels/3521")!

        let result = router.attemptMatch(url: url)?.route as! ViewChannel
        XCTAssertEqual(result.channelId, 3521)
    }

}
