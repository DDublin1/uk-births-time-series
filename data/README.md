# Data

## Dataset: UK Vital Statistics — Births

**Source:** [Office for National Statistics (ONS)](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths)  
**Format:** Excel (.xlsx)  
**License:** Open Government Licence v3.0

### Description
Annual UK birth statistics including live births by year, broken down by various demographic factors. The analysis uses aggregate birth counts over time to build a time series model.

### Key Fields
| Field | Description |
|-------|-------------|
| Year | Calendar year |
| Live Births | Total live births registered |
| Birth Rate | Births per 1,000 population |
| Female Population | Female population of childbearing age |

### Setup
Download the births data from ONS:
1. Visit: https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths
2. Download the Excel dataset for historical live births
3. Place the `.xlsx` file in this folder and update the file path in the R script accordingly
