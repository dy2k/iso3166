defmodule Iso3166.Country do
	defstruct [:continent, :address_format, :alpha2, :alpha3, :country_code,
             :international_prefix, :ioc, :gec, :name, :national_destination_code_lengths,
             :national_number_lengths, :national_prefix, :number, :region, :subregion,
             :world_region, :un_locode, :nationality, :postal_code, :unofficial_names,
             :languages_official, :languages_spoken, :geo, :currency_code]
end
