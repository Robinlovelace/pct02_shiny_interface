#     This is UI base that runs on every connected client
#
#     Copyright (C) 2016 Nikolai Berkoff, Ali Abbas and Robin Lovelace
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Affero General Public License as
#     published by the Free Software Foundation, either version 3 of the
#     License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Affero General Public License for more details.
#
#     You should have received a copy of the GNU Affero General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

library(shiny)
library(leaflet)
library(shinyjs)

purposes <- c(
  "Commuting"           = "commute",
  "School travel"       = "school",
  "All trips"           = "alltrips"
)

geographies <- c("Middle Super Output Area"  = "msoa" ,
                 "Lower Super Output Area"  = "lsoa")

scenarios <- c(
  "Census 2011 Cycling" = "olc",
  "Government Target"   = "govtarget",
  "Gender equality"     = "gendereq",
  "Go Dutch"            = "dutch",
  "Ebikes"              = "ebike"
)

line_types <- c(
  "None"                   = "none",
  "Straight Lines"         = "straight_lines",
  "Fast Routes"            = "routes_fast",
  "Fast & Quieter Routes"  = "routes",
  "Route Network (MSOA)"   = "route_network",
  "Route Network (LSOA)"   = "lsoa_base_map"
)

line_order <- c(
  "Number of cyclists" = "slc",
  "Increase in Cycling" = "sic",
  "HEAT Value"          = "slvalue_heat",
  "CO2 reduction"       = "sico2"
)

map_base_attrs <- c(
  "Roadmap (Black & White)" = "roadmap",
  "Roadmap (OpenCycleMap)"  = "opencyclemap",
  "Satellite"               = "satellite",
  "Index of Deprivation"    = "IMD",
  "Hilliness"               = "hilliness"
)

on_server <- grepl('^/var/shiny/pct-shiny', getwd())
#ANNA NOTE: CHANGE THIS 'pct-shiny'
production_branch <- grepl("npt\\d*$", Sys.info()["nodename"])

shinyUI(
  navbarPage(
    title = "Propensity to Cycle Tool",
    id = "nav",
    tabPanel(
      "Map",
      useShinyjs(),
      div(
        class = "outer",
        tags$head(
          if (on_server)
            includeScript("../www/assets/google-analytics.js"),
          tags$script(
            id = "locizify",
            projectid = "cefac43d-1a19-486e-bd7b-d5d2a518cfa4",
            debug = "false",
            apikey = "28c19049-fa53-4668-b708-fe92ff732e7c",
            saveMissing = "true",
            referencelng = "en",
            fallbacklng = "en",
            src = "https://unpkg.com/locizify@^2.0.0"
          ),
          includeScript("../www/assets/extra.js"),
          includeCSS("../www/stylesheet.css"),
          includeHTML(file.path("..", "favicon.html"))
        ),
        if (!production_branch) {
          includeHTML(file.path("..", "test-banner.html"))
        },
        br(),
        leafletOutput("map", width = "100%", height = "95%"),
        absolutePanel(
          id = "controls",
          class = "panel panel-default",
          fixed = TRUE,
          top = 110,
          right = 20,
          width = 180,
          height = "auto",
          style = "opacity: 0.9",
          tags$div(title = "Show/Hide Panel",
                   a(
                     id = "toggle_panel",
                     style = "font-size: 80%",
                     span(class = "glyphicon glyphicon-circle-arrow-up", "Hide")
                   )),
          div(
            id = "input_panel",
            if (!production_branch) {
              tags$div(title = "Trip purpose:",
                       selectInput("purpose", "Trip purpose:", purposes, selectize = F))
            },
            if (!production_branch) {
              tags$div(title = "Geography:",
                       selectInput("geography", "Geography:", geographies, selectize = F))
            },
            #hidden(selectInput("geography", "geography: ", geographies)),
            tags$div(
              title = "Scenario (see manual)",
              selectInput("scenario", "Scenario:", scenarios, selectize = F)
            ),
            tags$div(
              title = "Shows the cycling flow between the centres of zones",
              selectInput(
                "line_type",
                "Cycling Flows:",
                line_types,
                selected = "none",
                selectize = F
              )
            ),
            tags$div(title = "Shows the cycling flow between the centres of zones",
                     checkboxInput("show_zones", "Show Zones", value = T)),

            conditionalPanel(
              condition = "input.line_type != 'none' && input.line_type != 'lsoa_base_map' && input.line_type != 'route_network'",
              tags$div(title = "Untick to update lines when you move the map",
                       checkboxInput("freeze", "Freeze Lines", value = F))
            ),
            conditionalPanel(
              condition = "input.line_type != 'none' && input.line_type != 'lsoa_base_map'",
              tags$div(
                title = "Number of lines to show",
                sliderInput(
                  "nos_lines",
                  label = "Top N Lines (most cycled)",
                  1,
                  200,
                  value = 30,
                  ticks = F
                )
              ),
              conditionalPanel(
                condition = "input.line_type != 'route_network' && input.scenario != 'olc'",
                tags$div(
                  title = "Order the top flows by",
                  selectInput(
                    "line_order",
                    "Order lines by",
                    line_order,
                    selected = "slc",
                    selectize = F
                  )
                )
              )
            ),
            tags$div(
              title = "Change base of the map",
              selectInput("map_base", "Map Base:", map_base_attrs, selectize = F)
            )
          )
        ),
        conditionalPanel(
          condition = "input.map_base == 'IMD'",
          absolutePanel(
            cursor = "auto",
            id = "legend",
            class = "panel panel-default",
            bottom = 235,
            left = 5,
            height = 20,
            width = 225,
            draggable = TRUE,
            style = "opacity: 0.7",
            tags$div(
              title = "Show/Hide map legend",
              a(
                id = "toggle_imd_legend",
                style = "font-size: 80%",
                span(class = "glyphicon glyphicon-circle-arrow-up", "Hide")
              )
            ),
            div(
              id = "imd_legend",
              tags$div(title = "Index of Multiple Deprivation",
                       plotOutput(
                         "imd_legend", width = "100%", height = 180
                       ))
            )
          )
        ),
        tags$div(id = "cite",
                 htmlOutput("cite_html"))
      )
    ),

    tabPanel("Region stats",
             htmlOutput("region_stats")),
    tabPanel("Region data",
             htmlOutput("download_region_current")),
    tabPanel("National data",
             htmlOutput("download_national_current")),
    tabPanel("Manual",
             includeHTML(file.path("../tabs/manual_body.html"))),
    tabPanel("About",
             includeHTML(file.path("../tabs/about_body.html")))
  )
)
