HTMLWidgets.widget({

    name: 'tsne_linked',

    type: 'output',

    factory: function (el, width, height) {

        // TODO: define shared variables for this instance
        return {

            renderValue: function (x) {

                var options = x.options;

                var histogram_data = HTMLWidgets.dataframeToD3(x.histogram_data);
                var point_data = HTMLWidgets.dataframeToD3(x.point_data);
                //console.log(point_data);

                point_lims = [[1e9, -1e9], [1e9, -1e9]];
                group_var_range = [1000, -1000];

                function parse_histogram_data(data) {
                    hdata = {};
                    data.forEach(function (d) {
                        if (!hdata.hasOwnProperty(d.label_var)) {
                            hdata[d.label_var] = [];
                        }
                        hdata[d.label_var].push(d);
                    })
                    return hdata;
                }

                var hdata = parse_histogram_data(histogram_data);
                //console.log("parsed hdata", hdata);
                var current_id = histogram_data[0].label_var;

                point_data.forEach(function (d, i) {

                    var x = d.V1;
                    if (x < point_lims[0][0]) {
                        point_lims[0][0] = x;
                    }
                    if (x > point_lims[0][1]) {
                        point_lims[0][1] = x;
                    }

                    var x = d.V2;
                    if (x < point_lims[1][0]) {
                        point_lims[1][0] = x;
                    }
                    if (x > point_lims[1][1]) {
                        point_lims[1][1] = x;
                    }

                    if (+d.group_var < group_var_range[0]) {
                        group_var_range[0] = +d.group_var;
                    }

                    if (+d.group_var > group_var_range[1]) {
                        group_var_range[1] = +d.group_var;
                    }

                })

                var color_scale = d3.scaleOrdinal(d3.schemeCategory10)
                    .domain(group_var_range);

                var max_lim = d3.max([Math.abs(point_lims[0]), Math.abs(point_lims[1])]);
                //point_lims = [-max_lim, max_lim];

                // margin handling
                //   set our default margin to be 20
                //   will override with x.options.margin if provided
                var margin = { top: 20, right: 20, bottom: 20, left: 20 };

                var svg = d3.select(el)
                    .append("svg")
                    .attr("width", width)
                    .attr("height", height)
                    .append("g")
                    .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
                    .attr('id', 'mysvg');

                var scatter_dx = 0;
                var scatter_sz = 400;
                var scatter_scale_x = d3.scaleLinear()
                    .domain(point_lims[0])
                    .range([0, scatter_sz]);

                var scatter_scale_y = d3.scaleLinear()
                    .domain(point_lims[1])
                    .range([scatter_sz, 0]);

                var voronoi = d3.voronoi()
                    .x(function (d) { return scatter_scale_x(+d.V1) })
                    .y(function (d) { return scatter_scale_y(+d.V2) })
                    .extent(
                        [
                            [-margin.left, -margin.top],
                            [scatter_sz + margin.right, scatter_sz + margin.bottom]
                        ])
                    ;


                var scatter;
                function init_scatter(data) {

                    var yaxis = d3.axisLeft(scatter_scale_y);
                    var xaxis = d3.axisBottom(scatter_scale_x);

                    scatter = d3.select('#mysvg').append('g')
                        .attr('transform', function () {
                            return 'translate(' + scatter_dx + ',' + 0 + ')';
                        });

                    scatter.append('g')
                        .attr("transform", "translate(" + 0 + ", " + 0 + ")")
                        .call(yaxis)
                        .append("text")
                        .attr("transform", "rotate(-90)")
                        .attr("x", function () {
                            return 0 * 0.5 * scatter_sz;
                        })
                        .attr("y", function () {
                            return 6;
                        })
                        .attr("dy", "1em")
                        .attr("fill", "#000")
                        .text("V2")
                        .style("font", "10px sans-serif")
                        ;

                    scatter.append('g')
                        .attr("transform", "translate(" + 0 + ", " + scatter_sz + ")")
                        .call(xaxis)
                        .append("text")
                        .attr("transform", "rotate(0)")
                        .attr("x", function () {
                            return 0.5 * scatter_sz;
                        })
                        .attr("y", function () {
                            return 30;
                        })
                        .attr("fill", "#000")
                        .text("v1")
                        .style("font", "10px sans-serif")
                        ;

                    var idx1 = '1';
                    var idx2 = '1';
                    scatter.selectAll('.point')
                        .data(data)
                        .enter().append('circle')
                        .attr('class', 'point')
                        .attr('id', function (d) {
                            return 'point-' + d.label_var;
                        })
                        .style('fill', function (d) {
                            return color_scale(+d.group_var);
                        })
                        .attr('r', 2)
                        .attr('cx', function (d) {
                            return scatter_scale_x(d.V1)
                        })
                        .attr('cy', function (d) {
                            return scatter_scale_y(d.V2)
                        })
                        .on('mouseover', function (d) {
                            update_label(d);
                            update_histogram(hdata[d.label_var]);
                            set_current_highlight(d.label_var);
                        }).on('mouseover', function (d) {

                        })
                        ;
                }

                function redrawPolygon(polygon) {
                    polygon
                        .attr("d", function (d) { return d ? "M" + d.join("L") + "Z" : null; });
                }

                function init_label() {

                    svg.append('text')
                        .attr('id', 'clusterLabel')
                        .text('blah')
                        .attr('x', 500)
                        .attr('y', 20)
                        .style("font", "16px sans-serif")
                        .style('cursor', 'pointer')
                        .on('mouseover', function () {
                        })
                        ;


                }

                function update_label(x) {
                    d3.select('#clusterLabel')
                        .text(function () {
                            return "ID: " + x.label_var + " ";
                        })
                        ;

                }

                function range_(n) {
                    var arr = [];
                    for (var i = 0; i < n; i++) {
                        arr.push(i);
                    }
                    return arr;
                }

                // closures FTW
                function clamp(a, b) {
                    return function (x) {
                        return Math.max(a, Math.min(x, b));
                    }
                }

                var hx, hy;
                var hloc = [500, 50];
                var hsz = [400, 325];
                var histogram_svg;
                var tmp = histogram_data.map(d => Math.abs(d.coord_value));
                var scatter_ycap = Math.max(...tmp);
                var clamp_fun = clamp(0, scatter_ycap);

                function init_histogram(hdata) {

                //    console.log("init hdata", hdata);

                    var hdata_length = 10;
                    var hx_domain = [];
                    hdata.forEach(function (d) {
                        hx_domain.push(d.coord_name);
                    })
                    hx = d3.scaleBand().rangeRound([0, hsz[0]])
                        .domain(hx_domain).padding(0.1);

                    hy = d3.scaleLinear().range([hsz[1], 0]).domain([0, scatter_ycap]);

                    var yaxis = d3.axisLeft(hy);
                    var xaxis = d3.axisBottom(hx);//.tickValues([0, 12, 24, 36, 48, 60]);

                    histogram_svg = svg.append('g')
                        .attr('id', 'hsvg')
                        .attr('transform', function () {
                            return 'translate(' + hloc[0] + ',' + hloc[1] + ')';
                        })

                    histogram_svg.selectAll('.bar')
                        .data(hdata)
                        .enter()
                        .append('rect')
                        .attr('class', 'bar')
                        .attr('width', hx.bandwidth())
                        .attr('height', function (d) {
                            return hsz[1] - hy(clamp_fun(Math.abs(d.coord_value)));
                        })
                        .attr('x', function (d) {
                            return hx(d.coord_name);
                        })
                        .attr('y', function (d) {
                            return hy(clamp_fun(Math.abs(d.coord_value)));
                        })
                        .style('fill', 'steelblue')
                        .style('opacity', 1)

                        ;

                    histogram_svg.append('g')
                        .attr("transform", "translate(" + 0 + ", " + 0 + ")")
                        .call(yaxis)
                        .append("text")
                        .attr("transform", "rotate(-90)")
                        .attr("x", function () {
                            return 0;
                        })
                        .attr("y", function () {
                            return 6;
                        })
                        .attr("dy", "1em")
                        .attr("fill", "#000")
                        .text("coord. value")
                        .style("font", "10px sans-serif")
                        ;

                    histogram_svg.append('g')
                        .attr("transform", "translate(" + 0 + ", " + hsz[1] + ")")
                        .call(xaxis)
                        .append("text")
                        .attr("transform", "rotate(0)")
                        .attr("x", function () {
                            return 0.5 * hsz[1];
                        })
                        .attr("y", function () {
                            return 30;
                        })
                        .attr("fill", "#000")
                        .text("coord. name")
                        .style("font", "10px sans-serif")
                        ;
                }

                function update_histogram(hdata) {
                    //console.log("update!", hdata);
                    histogram_svg.selectAll('.bar')
                        .data(hdata)
                        .transition().duration(400)
                        .attr('width', hx.bandwidth())
                        .attr('height', function (d) {
                            return hsz[1] - hy(clamp_fun(Math.abs(d.coord_value)));
                        })
                        .attr('x', function (d) {
                            return hx(d.coord_name);
                        })
                        .attr('y', function (d) {
                            return hy(clamp_fun(Math.abs(d.coord_value)));
                        })
                        .style('fill', function (d) {
                            return color_scale(+d.group_var);
                        })
                        .style('opacity', function(d) {
                            return +d.coord_value >= 0 ? 1 : 0.5;
                        })
                }

                function set_current_highlight(id) {
                    if (id === current_id) {
                        return;
                    }
                    highlight_point_off(current_id);
                    current_id = id;
                    highlight_point_on(current_id);
                }

                function highlight_point_on(id) {
                    s = '#point-' + id;
                    console.log(s)
                    d3.select(s)
                        .transition()
                        .duration(200)
                        .attr('r', 4)
                        .style('opactity', 0.2)
                        ;
                }

                function highlight_point_off(id) {
                    s = '#point-' + id;
                    d3.select(s)
                        .transition()
                        .duration(400)
                        .attr('r', 2)
                        .style('opactity', 0.2)
                        ;
                }

                function init_voronoi(point_data) {
                    var v_polys = voronoi(point_data);
                    //console.log('v_polys', v_polys);

                    svg.append("g")
                        .attr("class", "polys")
                        .selectAll("path")
                        .data(voronoi.polygons(point_data))
                        .enter().append("path")
                        .style('fill', 'white')
                        .style('stroke', '#000')
                        .style('stroke-opacity', 0.0)
                        .attr("d", function (d) {
                            return d ? "M" + d.join("L") + "Z" : null;
                        })
                        .on('mouseover', function (d) {
                            update_label(d.data);
                            update_histogram(hdata[d.data.label_var]);
                            set_current_highlight(d.data.label_var);
                        })
                        .on('mouseout', function (d) {
                        })

                        ;

                }

                init_voronoi(point_data);
                init_scatter(point_data);
                init_label();

                init_histogram(hdata[current_id]);

            },

            resize: function (width, height) {

                // TODO: code to re-render the widget with a new size

            }

        };
    }
});
1
