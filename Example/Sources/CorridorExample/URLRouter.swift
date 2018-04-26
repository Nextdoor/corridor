
import Corridor
import Foundation

public class URLRouter {

    let router: CorridorRouter

    // Singleton shared instance
    public class var shared: URLRouter {
        struct Singleton {
            static let instance: URLRouter = URLRouter()
        }
        return Singleton.instance
    }

    init() {
        let globalParams = ["link_source_user_id", "action_source_user_id", "ct"]
        let globalParamDecoder: ([String: Any]) throws -> CorridorGlobalParams = {
            try corridorGlobalParamsResponse($0, GlobalParams.self)
        }
        let mapping = GlobalQueryOptionalParamsMapping(params: globalParams,
                                                       decoder: globalParamDecoder)
        self.router = CorridorRouter(globalQueryOptionalParamsMapping: mapping)
        registerRoutes()
    }

    private func registerRoutes() {
        router.register("/news_feed/?:post{int}&:message_to{int}", { try corridorResponse($0, PrivateMessageUser.self) })
        router.register("/news_feed/?:post{int}&:unsub{bool?}", { try corridorResponse($0, ViewPost.self) })
        router.register("/news_feed", { try corridorResponse($0, ViewNewsFeed.self) })

        router.register("/like_post/:post{int}", { try corridorResponse($0, ThankPost.self) })
        router.register("/like_comment/:comment{int}/?:post{int}", { try corridorResponse($0, LikeComment.self) })

        router.register("/profile/:profileId{int}", { try corridorResponse($0, ViewProfile.self) })
        router.register("/profile", { try corridorResponse($0, ViewProfileCurrentUser.self) })

        router.register("/email_prefs", { try corridorResponse($0, ViewEmailSettings.self) })

        router.register("/inbox/:chatId{string}", { try corridorResponse($0, ViewChatConversation.self) })

        router.register("/events/:eventId{int}", { try corridorResponse($0, ViewEvent.self) })
        router.register("/groups/:groupId{int}", { try corridorResponse($0, ViewGroup.self) })

        router.register("/favorites", { try corridorResponse($0, ViewRecommendationsFavorites.self) })
        router.register("/recommendations", { try corridorResponse($0, ViewRecommendations.self) })
        router.register("/recommendations/all_topics", { try corridorResponse($0, ViewRecommendationsAllTopics.self) })
        router.register("/recommendations/tag", { try corridorResponse($0, TagRecommendations.self) })
        router.register("/recommendations/winners", { try corridorResponse($0, ViewRecommendationsFavorites.self) })
        router.register("/recommend_business", { try corridorResponse($0, RecommendBusiness.self) })
        router.register("/tag_replies", { try corridorResponse($0, TagRecommendations.self) })

        router.register("/topic/:topicId{int}/?:recommend{bool?}", { try corridorResponse($0, ViewBusinessCategoryDetail.self) })

        router.register("/map", { try corridorResponse($0, ViewNeighborhoodMap.self) })

        router.register("/invitation_email/.*", { try corridorResponse($0, SendInvite.self) })
        router.register("/invitation_postcards/.*", { try corridorResponse($0, SendInvite.self) })

        router.register("/for_sale_and_free/:item{string}/?:init_source{string?}", { try corridorResponse($0, ViewClassifiedItem.self) })
        router.register("/for_sale_and_free?:init_source{string?}&:is_free{bool?}&:discounted_items_only{bool?}&:sort_order{int?}&:audience_type{int?}&:topic_ids{int?}", { try corridorResponse($0, ViewClassifiedSection.self) })

        router.register("/channels", { try corridorResponse($0, ViewChannelsSection.self) })
        router.register("/channels/:channelId{int}", { try corridorResponse($0, ViewChannel.self) })

        router.register("/real-estate", { try corridorResponse($0, ViewRealEstateSection.self) })
        router.register("/real-estate-listings/:listingId{int}", { try corridorResponse($0, ViewRealEstateListing.self) })
    }

    public func attemptMatch(url: URL) -> RouteResponse? {
        return router.attemptMatch(url: url)
    }

}

public struct GlobalParams: CorridorGlobalParams {
    private let actionSourceUserId: String?
    private let linkSourceUserId: String?

    public let emailId: String?

    public var emailReceiverId: Int? {
        let idStr: String? = actionSourceUserId ?? linkSourceUserId
        guard let idStrUnwrapped = idStr, let idInt = Int(idStrUnwrapped) else {
            return nil
        }
        return idInt
    }

    enum CodingKeys: String, CodingKey {
        case actionSourceUserId = "action_source_user_id"
        case linkSourceUserId = "link_source_user_id"
        case emailId = "ct"
    }
}

public struct ThankPost: CorridorRoute {
    public let postId: Int

    enum CodingKeys: String, CodingKey {
        case postId = "post"
    }
}

public struct ViewPost: CorridorRoute {
    public let postId: Int
    public let unsubscribe: Bool?

    enum CodingKeys: String, CodingKey {
        case postId = "post"
        case unsubscribe = "unsub"
    }
}

public struct LikeComment: CorridorRoute {
    public let postId: Int
    public let commentId: Int

    enum CodingKeys: String, CodingKey {
        case postId = "post"
        case commentId = "comment"
    }
}

public struct PrivateMessageUser: CorridorRoute {
    public let postId: Int
    public let recipientId: Int

    enum CodingKeys: String, CodingKey {
        case postId = "post"
        case recipientId = "message_to"
    }
}

public struct ViewProfile: CorridorRoute {
    public let profileId: Int
}

public struct ViewProfileCurrentUser: CorridorRoute {
}

public struct ViewEmailSettings: CorridorRoute {
}

public struct ViewChatConversation: CorridorRoute {
    public let chatId: String
}

public struct ViewEvent: CorridorRoute {
    public let eventId: Int
}

public struct ViewGroup: CorridorRoute {
    public let groupId: Int
}

public struct ViewNewsFeed: CorridorRoute {
}

public struct ViewRecommendations: CorridorRoute {
}

public struct ViewRecommendationsFavorites: CorridorRoute {
}

public struct ViewBusinessCategoryDetail: CorridorRoute {
    public let topicId: Int
    public let recommend: Bool?
}

public struct ViewRecommendationsAllTopics: CorridorRoute {
}

public struct TagRecommendations: CorridorRoute {
}

public struct RecommendBusiness: CorridorRoute {
}

public struct ViewNeighborhoodMap: CorridorRoute {
}

public struct SendInvite: CorridorRoute {
}

public struct ViewRealEstateSection: CorridorRoute {
}

public struct ViewRealEstateListing: CorridorRoute {
    public let listingId: Int
}

public struct ViewClassifiedSection: CorridorRoute {
    public let initSource: String?
    public let isFree: Bool?
    public let discounted: Bool?
    public let sortOrder: Int?
    public let audienceType: Int?
    public let topicId: Int?

    enum CodingKeys: String, CodingKey {
        case initSource = "init_source"
        case isFree = "is_free"
        case discounted = "discounted_items_only"
        case sortOrder = "sort_order"
        case audienceType = "audience_type"
        case topicId = "topic_ids"
    }
}

public struct ViewClassifiedItem: CorridorRoute {
    public let classifiedId: String
    public let initSource: String?

    enum CodingKeys: String, CodingKey {
        case classifiedId = "item"
        case initSource = "init_source"
    }
}

public struct ViewChannelsSection: CorridorRoute {
}

public struct ViewChannel: CorridorRoute {
    public let channelId: Int
}
