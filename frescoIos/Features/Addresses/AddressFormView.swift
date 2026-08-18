import SwiftUI

struct AddressFormView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    let address: Address?

    init(address: Address? = nil) {
        self.address = address
    }

    @State private var name = ""
    @State private var phone = ""
    @State private var line1 = ""
    @State private var city = ""
    @State private var postalCode = ""
    @State private var stateName = ""
    @State private var countryName = ""
    @State private var stateId: String?
    @State private var countryId: String?
    @State private var isDefault = false
    @State private var countries: [LocationOption] = []
    @State private var states: [LocationOption] = []
    @State private var submitting = false

    var body: some View {
        Form {
            Section {
                TextField("Full name", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Street Address", text: $line1)
                TextField("City", text: $city)
                TextField("Postal Code", text: $postalCode)
                    .keyboardType(.numberPad)
            }

            Section {
                if countries.isEmpty {
                    TextField("Country", text: $countryName)
                    TextField("State / Province", text: $stateName)
                } else {
                    Picker("Country", selection: Binding(
                        get: { countryId ?? countries.first?.id ?? "" },
                        set: { id in
                            countryId = id
                            countryName = countries.first(where: { $0.id == id })?.label ?? ""
                            stateId = nil
                            stateName = ""
                            Task { await loadStates() }
                        }
                    )) {
                        ForEach(countries) { option in
                            Text(option.label).tag(option.id)
                        }
                    }

                    if states.isEmpty {
                        TextField("State / Province", text: $stateName)
                    } else {
                        Picker("State / Province", selection: Binding(
                            get: { stateId ?? states.first?.id ?? "" },
                            set: { id in
                                stateId = id
                                stateName = states.first(where: { $0.id == id })?.label ?? ""
                            }
                        )) {
                            ForEach(states) { option in
                                Text(option.label).tag(option.id)
                            }
                        }
                    }
                }
                Toggle("Set as default", isOn: $isDefault)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if submitting {
                        ProgressView()
                    } else {
                        Text(address == nil ? "Save Address" : "Update Address")
                    }
                }
                .disabled(!canSave || submitting)
            }
        }
        .navigationTitle(address == nil ? "Add Address" : "Update Address")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear(perform: fillForm)
        .task {
            countries = await state.loadCountries()
            if countryId == nil, let first = countries.first {
                countryId = first.id
                countryName = first.label
            }
            await loadStates()
        }
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty &&
        !phone.trimmed.isEmpty &&
        !line1.trimmed.isEmpty &&
        !city.trimmed.isEmpty &&
        !postalCode.trimmed.isEmpty &&
        !countryName.trimmed.isEmpty &&
        !stateName.trimmed.isEmpty
    }

    private func fillForm() {
        guard let address else { return }
        name = address.name
        phone = address.phone
        line1 = address.line1
        city = address.city
        postalCode = address.postalCode
        stateName = address.state
        countryName = address.country
        stateId = address.stateId
        countryId = address.countryId
        isDefault = address.isDefault
    }

    private func loadStates() async {
        guard let countryId, !countryId.isEmpty else { return }
        states = await state.loadStates(countryId: countryId)
        if stateId == nil, let first = states.first {
            stateId = first.id
            stateName = first.label
        }
    }

    private func save() async {
        submitting = true
        let saved = Address(
            id: address?.id ?? "a-\(Int(Date().timeIntervalSince1970 * 1000))",
            name: name.trimmed,
            phone: phone.trimmed,
            line1: line1.trimmed,
            city: city.trimmed,
            state: stateName.trimmed,
            postalCode: postalCode.trimmed,
            country: countryName.trimmed,
            stateId: stateId,
            countryId: countryId,
            isDefault: isDefault
        )
        let ok = await state.upsertAddress(saved)
        submitting = false
        if ok {
            dismiss()
        }
    }
}
