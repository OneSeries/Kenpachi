// ContentRatingPicker.swift
// A view for selecting the content rating for parental controls.

import SwiftUI

struct ContentRatingPicker: View {
    @Binding var selection: ContentRating

    var body: some View {
        Picker("Allowed Content Rating", selection: $selection) {
            ForEach(ContentRating.allCases, id: \.self) { rating in
                Text(rating.displayName).tag(rating)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
