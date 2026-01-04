import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            session.language = session.language == "en" ? "ar" : "en"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text(session.language == "en" ? "العربية" : "English")
                        }
                        .font(.footnote.bold())
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button("skip".localized(session.language)) {
                        dismiss()
                    }
                    .padding()
                    .foregroundColor(.gray)
                }
                
                TabView(selection: $currentPage) {
                    OnboardingIntroPage().tag(0)
                    TutorialStepPage().tag(1)
                    TutorialStepTwoPage().tag(2)
                    TutorialStepFinishPage().tag(3)
                    InfoPage().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .environment(\.layoutDirection, session.language == "ar" ? .rightToLeft : .leftToRight)
                
                Button(action: {
                    if currentPage < 4 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        dismiss()
                    }
                }) {
                    Text(currentPage == 4 ? "get_started".localized(session.language) : "next".localized(session.language))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

struct OnboardingIntroPage: View {
    @EnvironmentObject var session: UserSession
    var body: some View {
            VStack(spacing: 24) {
                Image(systemName: "camera.shutter.button.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("welcome".localized(session.language))
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("intro_desc".localized(session.language))
                    .font(.headline)
                    .foregroundColor(.blue.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    FeatureSnippet(icon: "shield.check", text: "feature1".localized(session.language))
                    FeatureSnippet(icon: "bolt.fill", text: "feature2".localized(session.language))
                    FeatureSnippet(icon: "calendar", text: "feature3".localized(session.language))
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 30)
    }
}

struct TutorialStepPage: View {
    @EnvironmentObject var session: UserSession
    var body: some View {
        VStack(spacing: 24) {
            Text("step1_title".localized(session.language))
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("step1_desc".localized(session.language))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray.opacity(0.9))
                .padding(.horizontal, 30)
            
            Image("image1")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
                .overlay(
                    Group {
                        if UIImage(named: "image1") == nil {
                            VStack(spacing: 8) {
                                Text("⚠️").font(.largeTitle)
                                Text(session.language == "ar" ? "الصورة غير متوفرة" : "Preview Missing")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                )
        }
    }
}

struct TutorialStepTwoPage: View {
    @EnvironmentObject var session: UserSession
    var body: some View {
        VStack(spacing: 24) {
            Text("step2_title".localized(session.language))
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("step2_desc".localized(session.language))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray.opacity(0.9))
                .padding(.horizontal, 30)
            
            Image("image2")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
                .overlay(
                    Group {
                        if UIImage(named: "image2") == nil {
                            VStack(spacing: 8) {
                                Text("⚠️").font(.largeTitle)
                                Text(session.language == "ar" ? "الصورة غير متوفرة" : "Preview Missing")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                )
        }
    }
}

struct TutorialStepFinishPage: View {
    @EnvironmentObject var session: UserSession
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("step4_title".localized(session.language))
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            BulletPoint(number: 4, text: "step4_desc1".localized(session.language))
            BulletPoint(number: 5, text: "step4_desc2".localized(session.language))
            BulletPoint(number: 6, text: "step4_desc3".localized(session.language))
            
            Spacer()
        }
        .padding(40)
    }
}

struct BulletPoint: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            Text("\(number)")
                .font(.body.bold())
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))
            
            Text(text)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
    }
}

struct FeatureSnippet: View {
    let icon: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
                .foregroundColor(.gray)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
        }
    }
}

struct InfoPage: View {
    @EnvironmentObject var session: UserSession
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Label("features".localized(session.language), systemImage: "star.fill")
                        .font(.headline)
                    Text("features_desc".localized(session.language))
                        .font(.subheadline).foregroundColor(.gray)
                }
                
                Group {
                    Label("important_notes".localized(session.language), systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                    Text("notes_desc".localized(session.language))
                        .font(.subheadline).foregroundColor(.gray)
                }
                
                Group {
                    Label("disclaimer".localized(session.language), systemImage: "doc.text.fill")
                        .font(.headline)
                    Text("disclaimer_desc".localized(session.language))
                        .font(.caption).foregroundColor(.gray)
                }
            }
            .foregroundColor(.white)
            .padding(40)
        }
    }
}
