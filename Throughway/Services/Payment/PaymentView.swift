//
//  PaymentView.swift
//  Throughway
//
//  Created by passi on 5/6/26.
//

import SwiftUI
import iamport_ios

// MARK: - SwiftUI Wrapper

/// SwiftUI에서 iamport SDK 결제 창을 띄울 때 사용하는 View.
/// DetailView의 .sheet { } 안에서 사용한다.
struct IamportPaymentView: UIViewControllerRepresentable {

    let payment: IamportPayment
    /// 결제 완료(성공·실패·취소) 시 호출되는 콜백.
    /// response == nil 이면 사용자가 창을 닫은 것.
    let onComplete: @MainActor (IamportResponse?) -> Void

    func makeUIViewController(context: Context) -> IamportPaymentViewController {
        IamportPaymentViewController(payment: payment, onComplete: onComplete)
    }

    func updateUIViewController(_ uiViewController: IamportPaymentViewController,
                                context: Context) {}
}

// MARK: - UIViewController

final class IamportPaymentViewController: UIViewController {

    private let payment: IamportPayment
    private let onComplete: @MainActor (IamportResponse?) -> Void

    init(payment: IamportPayment,
         onComplete: @escaping @MainActor (IamportResponse?) -> Void) {
        self.payment = payment
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        startPayment()
    }

    private func startPayment() {
        Iamport.shared.payment(
            viewController: self,
            userCode: "imp14511373",    // LSLP 가맹점 식별코드
            payment: payment
        ) { [weak self] response in
            guard let self else { return }
            let callback = self.onComplete
            Task { @MainActor in
                callback(response)
            }
        }
    }
}
