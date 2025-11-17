using OpenTelemetry;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace cheese_app
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        private TracerProvider _tracerProvider;

        protected void Application_Start()
        {
            _tracerProvider = Sdk.CreateTracerProviderBuilder().AddAspNetInstrumentation()

            // Other configuration, like adding an exporter and setting resources
            .AddOtlpExporter()
            // .AddConsoleExporter()
            .AddSource("cheese-app-instrumented")
            .SetResourceBuilder(
                ResourceBuilder.CreateDefault()
                    .AddService(serviceName: "cheese-app-instrumented", serviceVersion: "1.0.0"))

            .Build();

            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        protected void Application_End()
        {
            _tracerProvider?.Dispose();
        }
    }
}
