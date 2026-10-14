import SwiftUI

/// The welcome guide (14.1): four pages, swiped on iOS, with arrow buttons and ← → on the Mac.
/// Skip on every page but the last, and Next, then Get Started, at the bottom. Full screen on
/// an iPhone, a sheet on an iPad, its own window on the Mac.
struct WelcomeGuideView: View {
    /// The Mac's guide window. A window rather than a sheet on the recipe window: Settings and
    /// the Help menu open it too, and Settings is a window of its own.
    static let windowID = "welcomeGuide"
    /// The iPad sheet and the Mac window. 680 pt fits the longest page, the last one with its
    /// storage choice, so the choice shows without scrolling; a page that still doesn't fit
    /// (large Dynamic Type, a long translation) scrolls.
    static let size = CGSize(width: 560, height: 680)
    static let pageAccessibilityIdentifier = "WelcomeGuidePage"

    @Bindable var viewModel: WelcomeGuideViewModel
    /// For the last page's storage choice; nil leaves the choice out.
    var settingsViewModel: SettingsViewModel?
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
                    WelcomeGuidePageView(
                        page: page,
                        accessibilityLabel: page.accessibilityLabel(at: index, of: viewModel.pages.count),
                        settingsViewModel: settingsViewModel
                    )
                    .containerRelativeFrame(.horizontal)
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

/// One page: the app icon or a symbol in a pink circle, the title, the text and its points,
/// then on the last page the storage choice. Centered; it scrolls when it doesn't fit.
struct WelcomeGuidePageView: View {
    let page: WelcomeGuidePage
    /// What VoiceOver reads for the page's text, which is one element (`WelcomeGuidePage`).
    var accessibilityLabel: String = ""
    var settingsViewModel: SettingsViewModel?

    @ViewBuilder private var artwork: some View {
        switch page.artwork {
        case .appIcon:
            // The icon as Icon Composer renders it, light and dark (app/Design/AppIcon/build.sh).
            Image(decorative: "WelcomeAppIcon")
                .resizable()
                .frame(width: 96, height: 96)
        case let .symbol(name):
            Image(systemName: name)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PCColor.onPink)
                .frame(width: 84, height: 84)
                .background(PCColor.pink, in: Circle())
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                text
                if page.offersStorageChoice, let settingsViewModel {
                    WelcomeStorageChoiceView(viewModel: settingsViewModel)
                }
            }
            .frame(maxWidth: 440)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
    }

    /// One element, so VoiceOver reads the text whole and says where it is; the storage choice
    /// after it stays a control of its own.
    private var text: some View {
        VStack(spacing: 18) {
            artwork
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(WelcomeGuideView.pageAccessibilityIdentifier)
    }
}

#if os(iOS)
extension View {
    /// Presents the welcome guide: full screen in a compact width (an iPhone), a sheet otherwise
    /// (an iPad).
    func welcomeGuide(
        isPresented: Binding<Bool>,
        viewModel: WelcomeGuideViewModel,
        settingsViewModel: SettingsViewModel? = nil
    ) -> some View {
        modifier(WelcomeGuidePresentation(isPresented: isPresented, viewModel: viewModel, settingsViewModel: settingsViewModel))
    }
}

private struct WelcomeGuidePresentation: ViewModifier {
    @Binding var isPresented: Bool
    let viewModel: WelcomeGuideViewModel
    let settingsViewModel: SettingsViewModel?
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
        WelcomeGuideView(viewModel: viewModel, settingsViewModel: settingsViewModel) { isPresented = false }
    }

    /// If the size class changes while the guide is open (an iPad resized in multitasking), one
    /// presentation closes and the other opens: the guide is marked seen and starts again from
    /// page 1. Left as is; it's rare and the guide still works.
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
    let settingsViewModel: SettingsViewModel
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        WelcomeGuideView(viewModel: viewModel, settingsViewModel: settingsViewModel) {
            dismissWindow(id: WelcomeGuideView.windowID)
        }
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
