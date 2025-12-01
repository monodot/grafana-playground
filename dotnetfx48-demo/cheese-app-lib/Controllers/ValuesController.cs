using OpenTelemetry.Trace;
using System;
using System.Collections.Generic;
using System.Diagnostics.Metrics;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace cheese_app.Controllers
{
    public class ValuesController : ApiController
    {

        private static readonly Meter MyMeter = new Meter("cheese_app.metrics", "1.0.0");
        private static readonly Counter<long> CheeseCreateCounter = MyMeter.CreateCounter<long>(
            name: "cheese.creations.total",
            description: "The number of cheese creations by store");

        // GET api/values
        public IEnumerable<string> Get()
        {
            var span = Tracer.CurrentSpan;
            span.SetAttribute("cheese.catalogue.size", 42);
            span.SetAttribute("cheese.catalogue.updated", DateTime.UtcNow.ToString("o"));

            return new string[] { "value1", "value2" };
        }

        // GET api/values/5
        public string Get(int id)
        {
            var span = Tracer.CurrentSpan;
            span.SetAttribute("cheese.store.origin", "FR");
            span.SetAttribute("cheese.strength", 5);
            span.SetAttribute("cheese.tasty", true);

            return "value";
        }

        // POST api/values
        public void Post([FromBody] string value)
        {
            var span = Tracer.CurrentSpan;

            IEnumerable<string> headerValues;
            if (Request.Headers.TryGetValues("X-Store-ID", out headerValues))
            {
                var headerValue = headerValues.FirstOrDefault();
                if (!string.IsNullOrEmpty(headerValue))
                {
                    span.SetAttribute("cheese.store.id", headerValue);

                    // Increment the counter with the store ID as an attribute
                    CheeseCreateCounter.Add(1, new KeyValuePair<string, object>("store.id", headerValue));
                }
            }
        }

        // PUT api/values/5
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/values/5
        public void Delete(int id)
        {
        }
    }
}
