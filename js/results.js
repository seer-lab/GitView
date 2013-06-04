/* The root URL for REST api */
var rootURL = "http://git_data.dom/api";

$(document).ready(function () {
    /* Display the election results when page is loaded */
    if (window.location.pathname.match(/index\.php/))
    {
        allCommits();
    }
});

function allCommits() {
    $.ajax({
        type: 'GET',
        url: rootURL + '/commits',
        dataType: "json", // data type of response
        success: function(data) {
            plotCommits(data);
        }
    });
}

function plotCommits(data) {

    //var results = value == null ? [] : (value instanceof Array ? value : [value]);

    //console.log(data)
    var comments = new Array(data["comments"].length);
    var code = new Array(data["code"].length);
    for (var i = 0; i < data["date"].length; i++) {

        //comments[i] = [moment(data["date"][i], "YYYY-MM-DD HH:mm:ss").toDate(), data["comments"][i]];
        //code[i] = [moment(data["date"][i], "YYYY-MM-DD HH:mm:ss").toDate(), data["code"][i]];

        comments[i] = [moment(data["date"][i], "YYYY-MM-DD").valueOf(), parseInt(data["comments"][i])];
        code[i] = [moment(data["date"][i], "YYYY-MM-DD").valueOf(), parseInt(data["code"][i])];
        //console.log(comments[i])

        //Do something
    }

    console.log(comments);
    console.log(code);

    areaPlot("container", comments, code)
    //plotPieChart(position, results);
    
}

function areaPlot(id, comments, code) {

    var chart = $('#container').highcharts({
            chart: {
                type: 'area'
                //xAxis: data["date"]
            },
            title: {
                text: 'Comment and Code Churn'
            },
            subtitle: {
                //TODO set to db query
                text: "nostra13" + "/" + "Android-Universal-Image-Loader"
            },
            xAxis: {
                type: 'datetime',
                labels: {
                formatter: function () {
                    return Highcharts.dateFormat('%b %Y', this.value);
                },
                dateTimeLabelFormats: {
                    month: '%b \'%y',
                    year: '%Y'
                }
            }
            },
            yAxis: {
                title: {
                    text: 'Number of Lines'
                },
                labels: {
                    formatter: function() {
                        return this.value / 1000 +'k';
                    }
                }
            },
            tooltip: {
                pointFormat: 'Number of Lines of {series.name}: <b>{point.y:,.0f}</b><br/>',
                shared: true
            },
            plotOptions: {
                area: {
                    
                    marker: {
                        enabled: false,
                        symbol: 'circle',
                        radius: 2,
                        states: {
                            hover: {
                                enabled: true
                            }
                        }
                    }
                }
            },
            series: [{
                name: 'Code',
                data: code,
                color: 'rgba(0, 0, 255, 0.7)'
                //color: 'rgba(255, 255, 255, 0.7)'
            }, {
                name: 'Comments',
                data: comments,
                color: 'rgba(0, 255, 0, 0.7)'
            }]
        });
    //chart.xAxis[0] = data["date"];
    /*var chart;
    var options = {
        chart: {
            type: 'area',
            renderTo: id
        },
        title: {
            text: "title"
        },
        series: [{
            name: 'USSR/Russia',
            data: [null, null, null, null, null, null, null , null , null ,null,
            5, 25, 50, 120, 150, 200, 426, 660, 869, 1060, 1605, 2471, 3322,
            4238, 5221, 6129, 7089, 8339, 9399, 10538, 11643, 13092, 14478,
            15915, 17385, 19055, 21205, 23044, 25393, 27935, 30062, 32049,
            33952, 35804, 37431, 39197, 45000, 43000, 41000, 39000, 37000,
            35000, 33000, 31000, 29000, 27000, 25000, 24000, 23000, 22000,
            21000, 20000, 19000, 18000, 18000, 17000, 16000]
        }]
    };
    chart = new Highcharts.Chart(options);*/
      /*      series: [{
                
            }, {
                name: 'USSR/Russia',
                data: [null, null, null, null, null, null, null , null , null ,null,
                5, 25, 50, 120, 150, 200, 426, 660, 869, 1060, 1605, 2471, 3322,
                4238, 5221, 6129, 7089, 8339, 9399, 10538, 11643, 13092, 14478,
                15915, 17385, 19055, 21205, 23044, 25393, 27935, 30062, 32049,
                33952, 35804, 37431, 39197, 45000, 43000, 41000, 39000, 37000,
                35000, 33000, 31000, 29000, 27000, 25000, 24000, 23000, 22000,
                21000, 20000, 19000, 18000, 18000, 17000, 16000]
            }]
        });*/
    /*$('#container').highcharts({
        chart: {
            
        },
        title: {
            text: 'Comment and Code Churn'
        },
        xAxis: {
            categories: data["date"]
        },
        yAxis: {
            title: {
                text: 'Number of Lines'
            }
        },
        series: [{
            name: 'Comments',
            data: data["comments"]
        }, {
            name: 'Code',
            data: data["code"]
        }],
    });*/
}