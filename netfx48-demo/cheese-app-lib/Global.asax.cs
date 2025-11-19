using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace cheese_app
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        private TracerProvider _tracerProvider;
        private MeterProvider _metricProvider;

        protected void Application_Start()
        {
            var resourceBuilder = ResourceBuilder.CreateDefault()
                .AddService(serviceName: "cheese-app-instrumented", serviceVersion: "1.0.0");

            _tracerProvider = Sdk.CreateTracerProviderBuilder()
                .AddAspNetInstrumentation()
                .AddOtlpExporter()
                .AddSource("cheese-app-instrumented")
                .SetResourceBuilder(resourceBuilder)
                .Build();

            _metricProvider = Sdk.CreateMeterProviderBuilder()
                .AddAspNetInstrumentation()
                .AddOtlpExporter()
                .AddMeter("cheese_app.metrics")
                .SetResourceBuilder(resourceBuilder)
                .Build();

            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        protected void Application_End()
        {
            // Dispose providers to flush remaining telemetry before shutdown
            _tracerProvider?.Dispose();
            _metricProvider?.Dispose();
        }
    }
}
