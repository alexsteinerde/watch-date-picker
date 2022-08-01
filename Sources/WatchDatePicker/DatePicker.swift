import SwiftUI

// TODO: move most of the configuration options to environment values
// TODO: determine `datePickerTwentyFourHour` automatically based on locale
// TODO: showsMonthBeforeDay: showsMonthBeforeDay ?? locale.monthComesBeforeDay
// TODO: determine the exact differences (if any) between `.sheet` and `.fullScreenCover` in watchOS
// TODO: don’t use both `accentColor` and `tint`
// TODO: somehow use a fallback tint of orange if possible

/// A control for the inputting of date and time values.
///
/// The `DatePicker` view displays a button with a title and the selected value. When pressed, it presents a sheet with user interfaces for selecting date and time. The view binds to a `Date` instance.
///
/// ![](DateAndTimeMode.png)
@available(watchOS 8, *)
@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public struct DatePicker: View {
  /// Option set that determines the displayed components of a date picker.
  ///
  /// Specifying ``date`` displays month, day, and year depending on the locale setting:
  /// ![](TimeMode.png)
  /// Specifying ``hourAndMinute`` displays hour, minute, and optionally AM/PM designation depending on the locale setting:
  /// ![](DateMode.png)
  /// Specifying both ``date`` and ``hourAndMinute`` displays date, hour, minute, and optionally AM/PM designation depending on the locale setting:
  /// ![](DateAndTimeMode.png)
  public struct Components: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    /// Displays day, month, and year based on the locale.
    public static let date = Self(rawValue: 1 << 0)
    
    /// Displays hour and minute components based on the locale.
    public static let hourAndMinute = Self(rawValue: 1 << 1)
  }

  var titleKey: LocalizedStringKey?
  @Binding var selection: Date
  var minimumDate: Date?
  var maximumDate: Date?
  var dateStyle: DateFormatter.Style = .medium
  var timeStyle: DateFormatter.Style = .short
  let displayedComponents: Components
  var onCompletion: ((Date) -> Void)?

  private func _onCompletion(_ date: Date) {
    sheetIsPresented = false
    onCompletion?(date)
  }

  @State private var sheetIsPresented = false
  @State private var linkIsActive = false

  @Environment(\.locale) private var locale

  @Environment(\.datePickerShowsMonthBeforeDay) private var showsMonthBeforeDay
  @Environment(\.datePickerTwentyFourHour) private var twentyFourHour

  private var formattedSelection: String {
    // TODO: don’t recreate the formatter every time? (maybe profile this or ask on Slack)
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateStyle = displayedComponents == .hourAndMinute ? .none : dateStyle
    formatter.timeStyle = displayedComponents == .date ? .none : timeStyle
    // if twentyFourHour == true && displayedComponents == .hourAndMinute {
    //   formatter.dateFormat = "HH:mm"
    // }
    return formatter.string(from: selection)
  }

  private var formattedDateSelection: String {
    // TODO: don’t recreate the formatter every time? (maybe profile this or ask on Slack)
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: selection)
  }

  private var label: some View {
    VStack(alignment: .leading) {
      if let label = titleKey {
        Text(label)
      }
      
      Text(formattedSelection)
        .font(titleKey != nil ? .footnote : .body)
        .foregroundStyle(titleKey != nil ? .secondary : .primary)
    }
  }
  
  private var confirmationButton: some View {
    Button(action: { linkIsActive = true }) {
      Text("Continue", bundle: .module)
    }
    .buttonStyle(.borderedProminent)
    .foregroundStyle(.background)
    .tint(.green)
    .scenePadding(.horizontal)
  }
  
  private var circularButtons: some View {
    HStack {
      Button(action: { sheetIsPresented = false }) {
        Image(systemName: "xmark")
      }
      .buttonStyle(.circular(.gray))
      
      Spacer()
      
      Button(action: { sheetIsPresented = false }) {
        Image(systemName: "checkmark")
      }
      .buttonStyle(.circular(.green))
    }
    .padding(.horizontal, 12)
  }

  /// The content and behavior of the view.
  public var body: some View {
    Button(action: { sheetIsPresented = true }) {
      label
    }
    .sheet(isPresented: $sheetIsPresented) {
      switch displayedComponents {
      case [.date, .hourAndMinute]:
        NavigationView {
          VStack(spacing: 15) {
            DateInputView(selection: $selection, minimumDate: minimumDate, maximumDate: maximumDate)
              .overlay {
                NavigationLink(isActive: $linkIsActive) {
                  TimeInputView(selection: $selection)
                    .navigationTitle(formattedDateSelection)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                      ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                          sheetIsPresented = false
                          
                          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            linkIsActive = false
                          }
                        }
                      }
                    }
                } label: {
                  EmptyView()
                }
                .hidden()
              }
            
            confirmationButton
          }
        }

      case .date:
        VStack(spacing: 15) {
          Spacer()
          
          DateInputView(selection: $selection, minimumDate: minimumDate, maximumDate: maximumDate)
            .frame(minHeight: 120)
          
          circularButtons
        }

      case .hourAndMinute:
        ZStack(alignment: .bottom) {
          TimeInputView(selection: $selection)
          
          circularButtons
            .padding(.bottom, -26)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("", action: {})
              .accessibilityHidden(true)
          }
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.all)
        .padding(.bottom, -40)
        .padding(.horizontal, -32)
        .offset(y: -45)
        
      default:
        EmptyView()
      }
    }
  }
}

@available(watchOS 8, *)
@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
extension DatePicker {
  /// Creates an instance that selects a Date with an unbounded range.
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.hourAndMinute, .date]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    displayedComponents: Components = [.hourAndMinute, .date]
  ) {
    self.titleKey = titleKey
    _selection = selection
    self.displayedComponents = displayedComponents
  }
  
  /// Creates an instance that selects a Date in a closed range.
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.hourAndMinute, .date]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.hourAndMinute, .date]
  ) {
    self.titleKey = titleKey
    _selection = selection
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }
  
  /// Creates an instance that selects a Date on or after some start date.
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.hourAndMinute, .date]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.hourAndMinute, .date]
  ) {
    self.titleKey = titleKey
    _selection = selection
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
  }
  
  /// Creates an instance that selects a Date on or before some end date.
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.hourAndMinute, .date]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.hourAndMinute, .date]
  ) {
    self.titleKey = titleKey
    _selection = selection
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
struct DatePicker_Previews: PreviewProvider {
  struct Example: View {
    @State var value = Calendar.current.date(bySettingHour: 10, minute: 09, second: 0, of: Date())!
    
    var body: some View {
      Form {
        DatePicker("Select Date & Time", selection: $value)
        DatePicker("Select Date", selection: $value, displayedComponents: .date)
        DatePicker("Select Time", selection: $value, displayedComponents: .hourAndMinute)
      }
      .tint(.orange)
      .accentColor(.orange)
    }
  }

  static var previews: some View {
    Example()
    
//    NavigationView {
//      TimeInputView(selection: .constant(Date()), mode: .time)
//        .datePickerSelectionIndicatorFill(.mint)
//        .toolbar {
//          ToolbarItem(placement: .cancellationAction) {
//            Button("Cancel", role: .cancel, action: {})
//          }
//        }
//    }
//    .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 6 - 44mm"))
//    .previewDisplayName("Mode: Time")
//
//    NavigationView {
//      DateInputView(selection: .constant(Date()), mode: .date)
//        .toolbar {
//          ToolbarItem(placement: .cancellationAction) {
//            Button("Cancel", role: .cancel, action: {})
//          }
//        }
//    }
//    .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 6 - 44mm"))
//    .previewDisplayName("Mode: Date (Series 6 – 44mm)")
//    .environment(\.locale, Locale(identifier: "da-DK"))
//
//    NavigationView {
//      DateInputView(selection: .constant(Date()), mode: .date)
//        .toolbar {
//          ToolbarItem(placement: .cancellationAction) {
//            Button("Cancel", role: .cancel, action: {})
//          }
//        }
//    }
//    .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 7 - 45mm"))
//    .previewDisplayName("Mode: Date (Series 7 – 45mm)")
//    .environment(\.locale, Locale(identifier: "da-DK"))
//
//    NavigationView {
//      DateInputView(selection: .constant(Date()), mode: .dateAndTime)
//        .toolbar {
//          ToolbarItem(placement: .cancellationAction) {
//            Button("Cancel", role: .cancel, action: {})
//          }
//        }
//    }
//    .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 6 - 44mm"))
//    .previewDisplayName("Mode: Date & Time (Step 1)")
//
//    NavigationView {
//      NavigationLink(isActive: .constant(true)) {
//        TimeInputView(selection: .constant(Date()), mode: .dateAndTime)
//          .datePickerTwentyFourHour()
//          .tint(.pink)
//      } label: {
//        EmptyView()
//      }
//      .opacity(0)
//    }
//    .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 6 - 44mm"))
//    .previewDisplayName("Mode: Date & Time (Step 2)")
  }
}
