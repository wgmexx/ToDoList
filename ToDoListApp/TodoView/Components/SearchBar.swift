import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.todoStroke)
                    .frame(width: 20, height: 22)
                    .padding(.leading, 5)
                
                TextField("Search", text: $text)
                    .foregroundColor(.todoStroke)
                    .padding(7)
                    .background(.todoGray)
                    .cornerRadius(10)
                
              
                    Image(systemName: "mic.fill")
                        .foregroundColor(.todoStroke)
                        .frame(width: 33, height: 33)
                
            }
            .padding(5)
            .background(.todoGray)
            .cornerRadius(10)
        }
    }
}
