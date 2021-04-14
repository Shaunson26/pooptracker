let labelFontSizer = (smallBreakPoint = 600, smallSize = 18, largeSize = 24) => {
    if (window.innerWidth < smallBreakPoint) {
      return smallSize
    } else {
      return largeSize
    }
  }

 function test(para_1, para_2, para_3) {
    if (para_1) {
        // First parameter set
    }
    if (para_2) {
        // Second parameter set
        console.log(para_2)
    }
    if (para_3) {
        // Third parameter set
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
                        display: typeof(labely) != 'undefined',
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
                        display: typeof(labelx) != 'undefined',
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