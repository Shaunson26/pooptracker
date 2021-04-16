/* 
poops.js 

Functions for the pooptracker webpage.

labelFontSizer - output number based on screensize
cjs - wrapper for chartJS chart
chartJS global settings
poopsOnLoad - inject values from poop_data.json

*/

let labelFontSizer = (smallBreakPoint = 600, smallSize = 18, largeSize = 24) => {
    if (window.innerWidth < smallBreakPoint) {
        return smallSize
    } else {
        return largeSize
    }
}

let cjs = function (id, data, x, y, type = 'bar',
    axisFontSizex = 24, axisFontSizey = 24,
    labelFontSizex, labelFontSizey, labelx, labely,
    borderWidth = 2) {

    let undef = function (x, what, then) {
        if (typeof x == what) {
            return then
        } else {
            return !then
        }
    }


    let ctx = document.getElementById(id).getContext('2d');

    new Chart(ctx, {
        plugins: [ChartRough],
        type: type,
        data: {
            labels: data[x],
            datasets: [{
                label: null,
                data: data[y],
                backgroundColor: data[y].map(() => '#87431d'),
                borderColor: data[y].map(() => '#87431d'),
                borderWidth: borderWidth,
                rough: {
                    roughness: 2,
                    bowing: 1
                }
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            events: [],
            legend: {
                display: false
            },
            scales: {
                yAxes: [{
                    scaleLabel: {
                        display: typeof (labely) != 'undefined',
                        labelString: labely,
                        fontSize: labelFontSizey,
                        padding: 4
                    },
                    gridLines: {
                        display: type == 'bar'
                    },
                    ticks: {
                        beginAtZero: true,
                        fontSize: axisFontSizey
                    }
                }],
                xAxes: [{
                    scaleLabel: {
                        display: typeof (labelx) != 'undefined',
                        labelString: labelx,
                        fontSize: labelFontSizex,
                        padding: 4
                    },
                    gridLines: {
                        display: type == 'horizontalBar'
                    },
                    ticks: {
                        fontSize: axisFontSizex
                    }
                }]
            }
        }
    });

}

Chart.defaults.global.defaultFontFamily = '"Indie Flower", cursive';
Chart.defaults.global.defaultFontSize = '24';


let poopsOnLoad = function () {

    fetch('./data/poop_data.json')
        .then(response => response.json())
        .then(data => {

            /* Insert values into text */

            for (x of [
                'start_date', 'end_date', 'n_days',
                'n_months', 'n_years', 'n_poops',
                'likely_n_poop', 'poop_rate',
                'likely_poop_time', 'often_poop_time',
                'often_poop_size', 'often_poop_type',
                'often_poop_place'
            ]) {
                document.querySelector('#' + x).innerText = data[x];
            }

            /* Plot data arrays */
            let windowWidth = window.innerWidth;
            let labelFontSize;
            if (windowWidth < 600) {
                labelFontSize = 18
            } else {
                labelFontSize = 24
            }

            let daily = data.daily
            let hourly = data.hourly
            let size = data.size
            let type1 = data.type
            let place = data.place

            cjs(id = 'plot-daily', data = daily, x = 'poops', y = 'prob', type = 'bar',
                axisFontSizex = 24, axisFontSizey = 24,
                labelFontSizex = labelFontSizer(), labelFontSizey = labelFontSizer(),
                labelx = 'Number of poops', labely = 'Probability (%)',
                borderWidth = 2)

            cjs(id = 'plot-hourly', data = hourly, x = 'hour', y = 'prob', type = 'bar',
                axisFontSizex = 16, axisFontSizey = 14,
                labelFontSizex = labelFontSizer(), labelFontSizey = labelFontSizer(),
                labelx = 'Hour of day', labely = 'Probability (%)',
                borderWidth = 1)

            cjs(id = 'plot-quantity', data = size, x = 'quantity', y = 'prob', type = 'horizontalBar',
                axisFontSizex = 16, axisFontSizey = 14,
                labelFontSizex = labelFontSizer(), labelFontSizey = labelFontSizer(),
                labelx = 'Probability (%)', labely = undefined)

            cjs(id = 'plot-type', data = type1, x = 'type', y = 'prob', type = 'horizontalBar',
                axisFontSizex = 16, axisFontSizey = 14,
                labelFontSizex = labelFontSizer(), labelFontSizey = labelFontSizer(),
                labelx = 'Probability (%)', labely = undefined)

            cjs(id = 'plot-place', data = place, x = 'place', y = 'prob', type = 'bar',
                axisFontSizex = 16, axisFontSizey = 14,
                labelFontSizex = labelFontSizer(), labelFontSizey = labelFontSizer(),
                labelx = undefined, labely = 'Probability (%)')


        })
}