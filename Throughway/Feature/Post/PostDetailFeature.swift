//
//  PostDetailFeature.swift
//  Throughway
//
//  Created by passi on 5/5/26.
//

import Foundation

enum PostDetailFeature {
    struct State: BaseState {
        var post: PostDTO?
        var comments: [CommentDTO] = []
        var isLoadingPost: Bool = false
        var isSubmittingComment: Bool = false
        var commentText: String = ""
        var replyingTo: (commentId: String, nick: String)? = nil
        var editingCommentId: String? = nil
        var likeOverride: (isLike: Bool, likeCount: Int)? = nil
    }

    enum Intent: BaseIntent {
        case onAppear
        case likeTapped
        case commentTextChanged(String)
        case replyTapped(commentId: String, nick: String)
        case cancelReply
        case submitComment
        case startEditing(commentId: String, content: String)
        case cancelEditing
        case deleteComment(commentId: String)
    }
}
