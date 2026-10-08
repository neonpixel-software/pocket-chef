import SwiftUI

/// The welcome guide (14.1): four pages, swiped on iOS, with arrow buttons and ← → on the Mac.
/// Skip on every page but the last, and Next, then Get Started, at the bottom. Full screen on
/// an iPhone, a sheet on an iPad, its own window on the Mac.
struct WelcomeGuideView: View {
    /// The Mac's guide window. A window rather than a sheet on the recipe window: Settings and
    /// the Help menu open it too, and Settings is a window of its own.
    static let windowID = "welcomeGuide"
    /// The iPad sheet and the Mac window. 520 pt fits the longest page; a page that still
    /// doesn't fit (large Dynamic Type, a long translation) scrolls.
    static let size = CGSize(width: 560, height: 520)
    static let pageAccessibilityIdentifier = "WelcomeGuidePage"

    @Bindable var viewModel: WelcomeGuideViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                if !viewModel.isOnLastPage {
                    Button("Skip", action: onClose)
                        .buttonStyle(.plain)
                        .font(PCFont.body(16, weight: .semibold))
                        .foregroundStyle(PCColor.textPrimary)
                        .keyboardShortcut(.cancelAction)
                }
            }
            // The same height with and without Skip, so the pages don't move on the last one.
            .frame(height: 28)

            pager

            PhotoPageDots(count: viewModel.pages.count, currentIndex: viewModel.currentIndex)

            Button(action: next) {
                Text(viewModel.isOnLastPage ? "Get Started" : "Next")
                    .font(PCFont.body(17, weight: .bold))
                    .foregroundStyle(PCColor.onPink)
                    .frame(maxWidth: 320)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(PCColor.pink)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .background(PCColor.background)
        .onAppear { viewModel.start() }
        // However the guide closes, including a swipe down on the iPad sheet.
        .onDisappear { viewModel.finish() }
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    WelcomeGuidePageView(page: page)
                        .containerRelativeFrame(.horizontal)
                        // One element per page, so VoiceOver reads it whole and says where it is.
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(page.accessibilityLabel(at: index, of: viewModel.pages.count))
                        .accessibilityIdentifier(Self.pageAccessibilityIdentifier)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $viewModel.currentPageID)
        .scrollIndicators(.hidden)
        #if os(macOS)
        .overlay {
            PhotoPagingArrows(
                canGoBack: viewModel.currentIndex > 0,
                canGoForward: !viewModel.isOnLastPage,
                previousLabel: "Previous Page",
                nextLabel: "Next Page",
                usesArrowKeys: true
            ) { step in
                withAnimation { viewModel.step(by: step) }
            }
        }
        #endif
    }

    private func next() {
        if viewModel.isOnLastPage {
            onClose()
        } else {
            withAnimation { viewModel.step(by: 1) }
        }
    }
}

/// One page: a symbol in a pink circle, the title, the text and its points. Centered; it
/// scrolls when it doesn't fit.
struct WelcomeGuidePageView: View {
    let page: WelcomeGuidePage

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: page.systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(PCColor.onPink)
                    .frame(width: 84, height: 84)
                    .background(PCColor.pink, in: Circle())
                    .accessibilityHidden(true)

                Text(page.title)
                    .font(PCFont.display(30))
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(PCFont.body(17))
                    .multilineTextAlignment(.center)

                if !page.items.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(page.items, id: \.self) { item in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(PCColor.teal)
                                Text(item)
                                    .font(PCFont.body(16))
                            }
                        }
                    }
                }

                if let note = page.note {
                    Text(note)
                        .font(PCFont.body(14))
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(PCColor.textPrimary)
            .frame(maxWidth: 440)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
    }
}

#if os(iOS)
extension View {
    /// Presents the welcome guide: full screen in a compact width (an iPhone), a sheet otherwise
    /// (an iPad).
    func welcomeGuide(isPresented: Binding<Bool>, viewModel: WelcomeGuideViewModel) -> some View {
        modifier(WelcomeGuidePresentation(isPresented: isPresented, viewModel: viewModel))
    }
}

private struct WelcomeGuidePresentation: ViewModifier {
    @Binding var isPresented: Bool
    let viewModel: WelcomeGuideViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: presented(fullScreen: true)) { guide }
            .sheet(isPresented: presented(fullScreen: false)) {
                guide
                    .frame(width: WelcomeGuideView.size.width, height: WelcomeGuideView.size.height)
                    .presentationSizing(.fitted)
            }
    }

    private var guide: some View {
        WelcomeGuideView(viewModel: viewModel) { isPresented = false }
    }

    private func presented(fullScreen: Bool) -> Binding<Bool> {
        Binding(
            get: { isPresented && (sizeClass == .compact) == fullScreen },
            set: { isPresented = $0 }
        )
    }
}
#endif

#if os(macOS)
/// The Mac's guide window: Skip and Get Started close it.
struct WelcomeGuideWindow: View {
    let viewModel: WelcomeGuideViewModel
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        WelcomeGuideView(viewModel: viewModel) { dismissWindow(id: WelcomeGuideView.windowID) }
            .frame(width: WelcomeGuideView.size.width, height: WelcomeGuideView.size.height)
    }
}

/// Help → Welcome Guide, in place of the default Help item, which searches for a help book the
/// app doesn't have.
struct WelcomeGuideCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Welcome Guide") { openWindow(id: WelcomeGuideView.windowID) }
        }
    }
}
#endif
